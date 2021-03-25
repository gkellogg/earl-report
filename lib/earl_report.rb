# EARL reporting
require 'json/ld'
require 'rdf/turtle'
require 'rdf/vocab'
require 'sparql'
require 'haml'
require 'open-uri'

##
# EARL reporting class.
# Instantiate a new class using one or more input graphs
class EarlReport
  autoload :VERSION, 'earl_report/version'

  attr_reader :graph
  attr_reader :verbose

  # Return information about each test.
  # Tests all have an mf:action property.
  # The Manifest lists all actions in list from mf:entries
  MANIFEST_QUERY = %(
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

    SELECT ?uri ?testAction ?manUri
    WHERE {
      ?uri mf:action ?testAction .
      OPTIONAL {
        ?manUri a mf:Manifest; mf:entries ?lh .
        ?lh rdf:first ?uri .
      }
    }
  ).freeze

  TEST_SUBJECT_QUERY = %(
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>

    SELECT DISTINCT ?uri ?name ?doapDesc ?release ?revision ?homepage ?language ?developer ?devName ?devType ?devHomepage
    WHERE {
      ?uri a doap:Project; doap:name ?name; doap:developer ?developer .
      OPTIONAL { ?uri doap:homepage ?homepage . }
      OPTIONAL { ?uri doap:description ?doapDesc . }
      OPTIONAL { ?uri doap:programming-language ?language . }
      OPTIONAL { ?uri doap:release ?release . }
      OPTIONAL { ?release doap:revision ?revision .}
      OPTIONAL { ?developer a ?devType .}
      OPTIONAL { ?developer foaf:name ?devName .}
      OPTIONAL { ?developer foaf:homepage ?devHomepage .}
    }
    ORDER BY ?name
  ).freeze

  DOAP_QUERY = %(
    PREFIX earl: <http://www.w3.org/ns/earl#>
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    
    SELECT DISTINCT ?subject ?name
    WHERE {
      [ a earl:Assertion; earl:subject ?subject ] .
      OPTIONAL {
        ?subject a doap:Project; doap:name ?name
      }
    }
  ).freeze

  ASSERTION_QUERY = %(
    PREFIX earl: <http://www.w3.org/ns/earl#>
    
    SELECT ?test ?subject ?by ?mode ?outcome
    WHERE {
      ?a a earl:Assertion;
        earl:assertedBy ?by;
        earl:result [earl:outcome ?outcome];
        earl:subject ?subject;
        earl:test ?test .
      OPTIONAL {
        ?a earl:mode ?mode .
      }
    }
    ORDER BY ?subject
  ).freeze

  TEST_FRAME = {
    "@context" => {
      "@version" =>     1.1,
      "@vocab" =>       "http://www.w3.org/ns/earl#",
      "foaf:homepage"=> {"@type" => "@id"},
      "dc" =>           "http://purl.org/dc/terms/",
      "doap" =>         "http://usefulinc.com/ns/doap#",
      "earl" =>         "http://www.w3.org/ns/earl#",
      "mf" =>           "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
      "foaf" =>         "http://xmlns.com/foaf/0.1/",
      "rdfs" =>         "http://www.w3.org/2000/01/rdf-schema#",
      "assertedBy" =>   {"@type" => "@id"},
      "assertions" =>   {"@type" => "@id", "@container" => "@set"},
      "bibRef" =>       {"@id" => "dc:bibliographicCitation"},
      "created" =>      {"@id" => "doap:created", "@type" => "xsd:date"},
      "description" =>  {"@id" => "rdfs:comment", "@language" => "en"},
      "developer" =>    {"@id" => "doap:developer", "@type" => "@id", "@container" => "@set"},
      "doapDesc" =>     {"@id" => "doap:description", "@language" => "en"},
      "generatedBy" =>  {"@type" => "@id"},
      "homepage" =>     {"@id" => "doap:homepage", "@type" => "@id"},
      "language" =>     {"@id" => "doap:programming-language"},
      "license" =>      {"@id" => "doap:license", "@type" => "@id"},
      "mode" =>         {"@type" => "@id"},
      "name" =>         {"@id" => "doap:name"},
      "outcome" =>      {"@type" => "@id"},
      "release" =>      {"@id" => "doap:release", "@type" => "@id"},
      "revision" =>     {"@id" => "doap:revision"},
      "shortdesc" =>    {"@id" => "doap:shortdesc", "@language" => "en"},
      "subject" =>      {"@type" => "@id"},
      "test" =>         {"@type" => "@id"},
      "testAction" =>   {"@id" => "mf:action", "@type" => "@id"},
      "testResult" =>   {"@id" => "mf:result", "@type" => "@id"},
      "title" =>        {"@id" => "mf:name"},
      "entries" =>      {"@id" => "mf:entries", "@type" => "@id", "@container" => "@list"},
      "testSubjects" => {"@type" => "@id", "@container" => "@set"},
      "xsd" =>          {"@id" => "http://www.w3.org/2001/XMLSchema#"}
    },
    "@requireAll" => true,
    "@embed" => "@always",
    "assertions" => {},
    "bibRef" => {},
    "generatedBy" => {
      "@embed" => "@always",
      "developer" => {"@embed" => "@always"},
      "release" => {"@embed" => "@always"}
    },
    "testSubjects" => {
      "@embed" => "@always",
      "@requireAll" => false,
      "@type" => "earl:TestSubject",
      "developer" => {"@embed" => "@always"},
      "release" => {"@embed" => "@always"},
      "homepage" => {"@embed" => "@never"}
    },
    "entries" => [{
      "@embed" => "@always",
      "@type" => "mf:Manifest",
      "entries" => [{
        "@embed" => "@always",
        "@type" => "earl:TestCase",
        "assertions" => {
          "@embed" => "@always",
          "@type" => "earl:Assertion",
          "assertedBy" => {"@embed" => "@never"},
          "result" => {
            "@embed" => "@always",
            "@type" => "earl:TestResult"
          },
          "subject" => {"@embed" => "@never"}
        }
      }]
    }]
  }.freeze

  TURTLE_PREFIXES = %(@prefix dc:   <http://purl.org/dc/terms/> .
  @prefix doap: <http://usefulinc.com/ns/doap#> .
  @prefix earl: <http://www.w3.org/ns/earl#> .
  @prefix mf:   <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#> .
  @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
  @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
  ).gsub(/^  /, '')

  TURTLE_SOFTWARE = %(
  # Report Generation Software
  <https://rubygems.org/gems/earl-report> a earl:Software, doap:Project;
     doap:name "earl-report";
     doap:shortdesc "Earl Report summary generator"@en;
     doap:description "EarlReport generates HTML+RDFa rollups of multiple EARL reports"@en;
     doap:homepage <https://github.com/gkellogg/earl-report>;
     doap:programming-language "Ruby";
     doap:license <http://unlicense.org>;
     doap:release <https://github.com/gkellogg/earl-report/tree/#{VERSION}>;
     doap:developer <https://greggkellogg.net/foaf#me> .

  <https://github.com/gkellogg/earl-report/tree/#{VERSION}> a doap:Version;
    doap:name "earl-report-#{VERSION}";
    doap:created "#{File.mtime(File.expand_path('../../VERSION', __FILE__)).strftime('%Y-%m-%d')}"^^xsd:date;
    doap:revision "#{VERSION}" .
  ).gsub(/^  /, '')

  # Convenience vocabularies
  class EARL < RDF::Vocabulary("http://www.w3.org/ns/earl#"); end
  class MF < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#"); end

  ##
  # Load test assertions and look for referenced software and developer information
  #
  # @param [Array<String>] files Assertions
  # @param [String] base (nil) Base IRI for loading Manifest
  # @param [String] bibRef ('Unknown reference')
  #   ReSpec bibliography reference for specification being tested
  # @param [Boolean] json (false) File is in the JSON format of a report.
  # @param [String, Array<String>] manifest (nil) Test manifest(s)
  # @param [String] name ('Unknown') Name of specification
  # @param [String] query (MANIFEST_QUERY)
  #   Query, or file containing query for extracting information from Test manifests
  # @param [Boolean] strict (false) Abort on any warning
  # @param [Boolean] verbose (false)
  def initialize(*files,
                 base: nil,
                 bibRef: 'Unknown reference',
                 json: false,
                 manifest: nil,
                 name: 'Unknown',
                 query: MANIFEST_QUERY,
                 strict: false,
                 verbose: false,
                 **options)
    @verbose = verbose
    raise "Test Manifests must be specified with :manifest option" unless manifest || json
    raise "Require at least one input file" if files.empty?
    @files = files
    @prefixes = {}
    @warnings = 0

    # If provided json, it is used for generating all other output forms
    if json
      @json_hash = ::JSON.parse(File.read(files.first))
      # Add a base_uri so relative subjects aren't dropped
      JSON::LD::Reader.open(files.first, base_uri: "http://example.org/report") do |r|
        @graph = RDF::Graph.new
        r.each_statement do |statement|
          # restore relative subject
          statement.subject = RDF::URI("") if statement.subject == "http://example.org/report"
          @graph << statement
        end
      end
      return
    end

    # Load manifests, possibly with base URI
    status "read #{manifest.inspect}"
    man_opts = {}
    man_opts[:base_uri] = RDF::URI(base) if base
    @graph = RDF::Graph.new
    Array(manifest).each do |man|
      g = RDF::Graph.load(man, unique_bnodes: true, **man_opts)
      status "  loaded #{g.count} triples from #{man}"
      graph << g
    end

    # Hash test cases by URI
    tests = SPARQL.execute(query, graph)
      .to_a
      .inject({}) {|memo, soln| memo[soln[:uri]] = soln; memo}

    if tests.empty?
      raise "no tests found querying manifest.\n" +
            "Results are found using the following query, this can be overridden using the --query option:\n" +
            "#{query}"
    end

    # Manifests in graph
    man_uris = tests.values.map {|v| v[:manUri]}.uniq.compact
    test_resources = tests.values.map {|v| v[:uri]}.uniq.compact
    subjects = {}

    # Initialize test assertions with an entry for each test subject
    test_assertion_lists = {}
    test_assertion_lists = tests.keys.inject({}) do |memo, test|
      memo.merge(test => [])
    end

    assertion_stats = {}

    # Read test assertion files into assertion graph
    files.flatten.each do |file|
      status "read #{file}"
      file_graph = RDF::Graph.load(file)
      if file_graph.first_object(predicate: RDF::URI('http://www.w3.org/ns/earl#testSubjects'))
        warn "   skip #{file}, which seems to be a previous rollup earl report"
        @files -= [file]
      else
        status "  loaded #{file_graph.count} triples"

        # Find or load DOAP descriptions for all subjects
        SPARQL.execute(DOAP_QUERY, file_graph).each do |solution|
          subject = solution[:subject]

          # Load DOAP definitions
          unless solution[:name] # not loaded
            status "  read doap description for #{subject}"
            begin
              doap_graph = RDF::Graph.load(subject)
              status "    loaded #{doap_graph.count} triples"
              file_graph << doap_graph.to_a
            rescue
              warn "\nfailed to load DOAP from #{subject}: #{$!}"
            end
          end
        end

        # Sanity check loaded graph, look for test subject
        solutions = SPARQL.execute(TEST_SUBJECT_QUERY, file_graph)
        if solutions.empty?
          warn "\nTest subject info not found for #{file}, expect DOAP description of project solving the following query:\n" +
            TEST_SUBJECT_QUERY
          next
        end

        # Load developers referenced from Test Subjects
        if !solutions.first[:developer]
          warn "\nNo developer identified for #{solutions.first[:uri]}"
        elsif !solutions.first[:devName]
          status "  read description for developer #{solutions.first[:developer].inspect}"
          begin
            foaf_graph = RDF::Graph.load(solutions.first[:developer])
            status "    loaded #{foaf_graph.count} triples"
            file_graph << foaf_graph.to_a
            # Reload solutions
            solutions = SPARQL.execute(TEST_SUBJECT_QUERY, file_graph)
          rescue
            warn "\nfailed to load FOAF from #{solutions.first[:developer]}: #{$!}"
          end
        end

        release = nil
        solutions.each do |solution|
          # Kepp track of subjects
          subjects[solution[:uri]] = RDF::URI(file)

          # Add TestSubject information to main graph
          doapName = solution[:name].to_s if solution[:name]
          language = solution[:language].to_s if solution[:language]
          doapDesc = solution[:doapDesc] if solution[:doapDesc]
          doapDesc.language ||= :en if doapDesc
          devName = solution[:devName].to_s if solution[:devName]
          graph << RDF::Statement(solution[:uri], RDF.type, RDF::Vocab::DOAP.Project)
          graph << RDF::Statement(solution[:uri], RDF.type, EARL.TestSubject)
          graph << RDF::Statement(solution[:uri], RDF.type, EARL.Software)
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP.name, doapName)
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP.developer, solution[:developer])
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP.homepage, solution[:homepage]) if solution[:homepage]
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP.description, doapDesc) if doapDesc
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP[:"programming-language"], language) if solution[:language]
          graph << RDF::Statement(solution[:developer], RDF.type, solution[:devType]) if solution[:devType]
          graph << RDF::Statement(solution[:developer], RDF::Vocab::FOAF.name, devName) if devName
          graph << RDF::Statement(solution[:developer], RDF::Vocab::FOAF.homepage, solution[:devHomepage]) if solution[:devHomepage]

          # Make sure BNode identifiers don't leak
          release ||= if !solution[:release] || solution[:release].node?
            RDF::Node.new
          else
            solution[:release]
          end
          graph << RDF::Statement(solution[:uri], RDF::Vocab::DOAP.release, release)
          graph << RDF::Statement(release, RDF::Vocab::DOAP.revision, (solution[:revision] || "unknown"))
        end

        # Make sure that each assertion matches a test and add reference from test to assertion
        found_solutions = false
        subject = nil

        status "  query assertions"
        SPARQL.execute(ASSERTION_QUERY, file_graph).each do |solution|
          subject = solution[:subject]
          unless tests[solution[:test]]
            assertion_stats["Skipped"] = assertion_stats["Skipped"].to_i + 1
            warn "Skipping result for #{solution[:test]} for #{subject}, which is not defined in manifests"
            next
          end
          unless subjects[subject]
            assertion_stats["Missing Subject"] = assertion_stats["Missing Subject"].to_i + 1
            warn "No test result subject found for #{subject}: in #{subjects.keys.join(', ')}"
            next
          end
          found_solutions ||= true
          assertion_stats["Found"] = assertion_stats["Found"].to_i + 1

          # Add this solution at the appropriate index within that list
          ndx = subjects.keys.find_index(subject)
          ary = test_assertion_lists[solution[:test]]

          ary[ndx] = a = RDF::Node.new
          graph << RDF::Statement(a, RDF.type, EARL.Assertion)
          graph << RDF::Statement(a, EARL.subject, subject)
          graph << RDF::Statement(a, EARL.test, solution[:test])
          graph << RDF::Statement(a, EARL.assertedBy, solution[:by])
          graph << RDF::Statement(a, EARL.mode, solution[:mode]) if solution[:mode]
          r = RDF::Node.new
          graph << RDF::Statement(a, EARL.result, r)
          graph << RDF::Statement(r, RDF.type, EARL.TestResult)
          graph << RDF::Statement(r, EARL.outcome, solution[:outcome])
        end

        # See if subject did not report results, which may indicate a formatting error in the EARL source
        warn "No results found for #{subject} using #{ASSERTION_QUERY}" unless found_solutions
      end
    end

    # Add ordered assertions for each test
    test_assertion_lists.each do |test, ary|
      ary[subjects.length - 1] ||= nil # extend for all subjects
      # Fill any missing entries with an untested outcome
      ary.each_with_index do |a, ndx|
        unless a
          assertion_stats["Untested"] = assertion_stats["Untested"].to_i + 1
          ary[ndx] = a = RDF::Node.new
          graph << RDF::Statement(a, RDF.type, EARL.Assertion)
          graph << RDF::Statement(a, EARL.subject, subjects.keys[ndx])
          graph << RDF::Statement(a, EARL.test, test)
          r = RDF::Node.new
          graph << RDF::Statement(a, EARL.result, r)
          graph << RDF::Statement(r, RDF.type, EARL.TestResult)
          graph << RDF::Statement(r, EARL.outcome, EARL.untested)
        end

        # This counts on order being preserved in default repository so we can avoid using an rdf:List
        graph << RDF::Statement(test, EARL.assertions, a)
      end
    end

    assertion_stats.each {|stat, count| status("Assertions #{stat}: #{count}")}

    # Add report wrapper to graph
    ttl = TURTLE_PREFIXES + %(
    <> a earl:Software, doap:Project;
    doap:name #{quoted(name)};
    dc:bibliographicCitation "#{bibRef}";
    earl:generatedBy <https://rubygems.org/gems/earl-report>;
    earl:assertions #{subjects.values.map {|f| f.to_ntriples}.join(",\n          ")};
    earl:testSubjects #{subjects.keys.map {|f| f.to_ntriples}.join(",\n          ")};
    mf:entries (#{man_uris.map {|f| f.to_ntriples}.join("\n          ")}) .
    ).gsub(/^    /, '') +
      TURTLE_SOFTWARE
    RDF::Turtle::Reader.new(ttl) {|r| graph << r}

    # Each manifest is an earl:Report
    man_uris.each do |u|
      graph << RDF::Statement.new(u, RDF.type, EARL.Report)
    end

    # Each subject is an earl:TestSubject
    subjects.keys.each do |u|
      graph << RDF::Statement.new(u, RDF.type, EARL.TestSubject)
    end

    # Each assertion test is a earl:TestCriterion and earl:TestCase
    test_resources.each do |u|
      graph << RDF::Statement.new(u, RDF.type, EARL.TestCriterion)
      graph << RDF::Statement.new(u, RDF.type, EARL.TestCase)
    end

    raise "Warnings issued in strict mode" if strict && @warnings > 0
  end

  ##
  # Dump the coalesced output graph
  #
  # If no `io` option is provided, the output is returned as a string
  #
  # @param [Symbol] format (:html)
  # @param [IO] io (nil)
  #   `IO` to output results
  # @param [Hash{Symbol => Object}] options
  # @param [String] template
  #   HAML template for generating report
  # @return [String] serialized graph, if `io` is nil
  def generate(format: :html, io: nil, template: nil, **options)

    status("generate: #{format}")
    ##
    # Retrieve Hashed information in JSON-LD format
    case format
    when :jsonld, :json
      json = json_hash.to_json(JSON::LD::JSON_STATE)
      io.write(json) if io
      json
    when :turtle, :ttl
      if io
        earl_turtle(io: io)
      else
        io = StringIO.new
        earl_turtle(io: io)
        io.rewind
        io.read
      end
    when :html
      haml = case template
      when String then template
      when IO, StringIO then template.read
      else
        File.read(File.expand_path('../earl_report/views/earl_report.html.haml', __FILE__))
      end

      # Generate HTML report
      html = Haml::Engine.new(haml, format: :xhtml).render(self, tests: json_hash)
      io.write(html) if io
      html
    else
      writer = RDF::Writer.for(format)
      writer.dump(@graph, io, standard_prefixes: true, **options)
    end
  end

  private
  
  ##
  # Return hashed EARL report in JSON-LD form
  # @return [Hash]
  def json_hash
    @json_hash ||= begin
      # Customized JSON-LD output
      result = JSON::LD::API.fromRDF(graph) do |expanded|
        framed = JSON::LD::API.frame(expanded, TEST_FRAME,
          expanded: true,
          embed: '@never',
          pruneBlankNodeIdentifiers: false)
        # Reorder test subjects by @id
        framed['testSubjects'] = Array(framed['testSubjects']).sort_by {|t| t['@id']}

        # Reorder test assertions to make them consistent with subject order
        Array(framed['entries']).each do |manifest|
          manifest['entries'].each do |test|
            test['assertions'] = test['assertions'].sort_by {|a| a['subject']}
          end
        end
        framed
      end
      unless result.is_a?(Hash)
        raise "Expected JSON result to have a single entry, it had #{result.length rescue 'unknown'} entries"
      end
      result
    end
  end

  ##
  # Output consoloated EARL report as Turtle
  # @param [IO] io ($stdout)
  #   `IO` to output results
  # @return [String]
  def earl_turtle(io: $stdout)
    context = JSON::LD::Context.parse(json_hash['@context'])
    io.write(TURTLE_PREFIXES + "\n")

    # Write project header
    ttl_entity(io, json_hash, context)

    # Write out each manifest entry
    io.puts("# Manifests")
    json_hash['entries'].each do |man|
      ttl_entity(io, man, context)

      # Output each test entry with assertions
      man['entries'].each do |entry|
        ttl_entity(io, entry, context)
      end
    end

    # Output each DOAP
    json_hash['testSubjects'].each do |doap|
      ttl_entity(io, doap, context)

      # FOAF
      dev = doap['developer']
      dev = [dev] unless dev.is_a?(Array)
      dev.each do |foaf|
        ttl_entity(io, foaf, context)
      end
    end
    
    io.write(TURTLE_SOFTWARE)
  end

  def ttl_entity(io, entity, context)
    io.write(ttl_value(entity) + " " + entity.map do |dk, dv|
      case dk
      when '@context', '@id'
        nil
      when '@type'
        "a " + ttl_value(dv)
      when 'assertions'
        "earl:assertions #{dv.map {|a| ttl_assertion(a)}.join(", ")}"
      when 'entries'
        "mf:entries #{ttl_value({'@list' => dv}, whitespace: "\n    ")}"
      when 'release'
        "doap:release [doap:revision #{quoted(dv['revision'])}]"
      else
        dv = [dv] unless dv.is_a?(Array)
        dv = dv.map {|v| v.is_a?(Hash) ? v : context.expand_value(dk, v)}
        "#{ttl_value(dk)} #{ttl_value(dv, whitespace: "\n    ")}"
      end
    end.compact.join(" ;\n  ") + " .\n\n")
  end

  def ttl_value(value, whitespace: " ")
    if value.is_a?(Array)
      value.map {|v| ttl_value(v)}.join(",#{whitespace}")
    elsif value.is_a?(Hash)
      if value.key?('@list')
        "(#{value['@list'].map {|vv| ttl_value(vv)}.join(whitespace)})"
      elsif value.key?('@value')
        quoted(value['@value'], language: value['@language'], datatype: value['@type'])
      elsif value.key?('@id')
        ttl_value(value['@id'])
      else
        "[]"
      end
    elsif value.start_with?(/https?/) || value.start_with?('/')
      "<#{value}>"
    elsif value.include?(':')
      value
    elsif json_hash['@context'][value].is_a?(Hash)
      json_hash['@context'][value].fetch('@id', "earl:#{value}")
    elsif value.empty?
      "<>"
    else
      "earl:#{value}"
    end
  end

  def ttl_assertion(value)
    return ttl_value(value) if value.is_a?(String)
    block = [
      "[",
      "    a earl:Assertion ;",
      "    earl:test #{ttl_value(value['test'])} ;",
      "    earl:subject #{ttl_value(value['subject'])} ;",
      "    earl:result [",
      "      a earl:TestResult ;",
      "      earl:outcome #{ttl_value(value['result']['outcome'])}",
      "    ] ;",
    ]
    block << "    earl:assertedBy #{ttl_value(value['assertedBy'])} ;" if value['assertedBy']

    block.join("\n") + "\n  ]"
  end

  def quoted(string, language: nil, datatype: nil)
    str = (@turtle_writer ||= RDF::Turtle::Writer.new).send(:quoted, string)
    str += "@#{language}" if language
    str += "^^#{ttl_value(datatype)}" if datatype
    str
  end

  def warn(message)
    @warnings += 1
    $stderr.puts message
  end

  def status(message)
    $stderr.puts message if verbose
  end
end
