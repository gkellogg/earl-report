# EARL reporting
require 'linkeddata'
require 'sparql'
require 'haml'

##
# EARL reporting class.
# Instantiate a new class using one or more input graphs
class EarlReport
  autoload :VERSION, 'earl_report/version'

  attr_reader :graph

  # Return information about each test, and for the first test in the
  # manifest, about the manifest itself
  MANIFEST_QUERY = %(
    PREFIX dc: <http://purl.org/dc/terms/>
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT ?lh ?uri ?type ?title ?description ?testAction ?testResult ?manUri  ?manComment
    WHERE {
      ?uri a ?type;
        mf:name ?title;
        mf:action ?testAction .
      OPTIONAL { ?uri rdfs:comment ?description . }
      OPTIONAL { ?uri mf:result ?testResult . }
      OPTIONAL {
        ?manUri a mf:Manifest; mf:entries ?lh .
        ?lh rdf:first ?uri .
        OPTIONAL { ?manUri rdfs:comment ?manComment . }
      }
    }
  ).freeze

  TEST_SUBJECT_QUERY = %(
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    
    SELECT DISTINCT ?uri ?name ?doapDesc ?homepage ?language ?developer ?devName ?devType ?devHomepage
    WHERE {
      ?uri a doap:Project; doap:name ?name .
      OPTIONAL { ?uri doap:developer ?developer .}
      OPTIONAL { ?uri doap:homepage ?homepage . }
      OPTIONAL { ?uri doap:description ?doapDesc . }
      OPTIONAL { ?uri doap:programming-language ?language . }
      OPTIONAL { ?developer a ?devType .}
      OPTIONAL { ?developer foaf:name ?devName .}
      OPTIONAL { ?developer foaf:homepage ?devHomepage .}
    }
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
    
    SELECT ?by ?mode ?outcome ?subject ?test
    WHERE {
      [ a earl:Assertion;
        earl:assertedBy ?by;
        earl:mode ?mode;
        earl:result [earl:outcome ?outcome];
        earl:subject ?subject;
        earl:test ?test ] .
    }
    ORDER BY ?subject
  ).freeze

  TEST_CONTEXT = {
    "@vocab" =>   "http://www.w3.org/ns/earl#",
    "foaf:homepage" => {"@type" => "@id"},
    dc:           "http://purl.org/dc/terms/",
    doap:         "http://usefulinc.com/ns/doap#",
    earl:         "http://www.w3.org/ns/earl#",
    mf:           "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
    foaf:         "http://xmlns.com/foaf/0.1/",
    rdfs:         "http://www.w3.org/2000/01/rdf-schema#",
    assertedBy:   {"@type" => "@id"},
    assertions:   {"@type" => "@id", "@container" => "@list"},
    bibRef:       {"@id" => "dc:bibliographicCitation"},
    created:      {"@id" => "doap:created", "@type" => "xsd:date"},
    description:  {"@id" => "dc:description", "@language" => "en"},
    developer:    {"@id" => "doap:developer", "@type" => "@id", "@container" => "@set"},
    doapDesc:     {"@id" => "doap:description", "@language" => "en"},
    generatedBy:  {"@type" => "@id"},
    homepage:     {"@id" => "doap:homepage", "@type" => "@id"},
    label:        {"@id" => "rdfs:label", "@language" => "en"},
    language:     {"@id" => "doap:programming-language"},
    license:      {"@id" => "doap:license", "@type" => "@id"},
    mode:         {"@type" => "@id"},
    name:         {"@id" => "doap:name"},
    outcome:      {"@type" => "@id"},
    release:      {"@id" => "doap:release", "@type" => "@id"},
    shortdesc:    {"@id" => "doap:shortdesc", "@language" => "en"},
    subject:      {"@type" => "@id"},
    test:         {"@type" => "@id"},
    testAction:   {"@id" => "mf:action", "@type" => "@id"},
    testResult:   {"@id" => "mf:result", "@type" => "@id"},
    entries:      {"@id" => "mf:entries", "@type" => "@id", "@container" => "@list"},
    testSubjects: {"@type" => "@id", "@container" => "@list"},
    title:        {"@id" => "dc:title"},
    xsd:          {"@id" => "http://www.w3.org/2001/XMLSchema#"}
  }.freeze

  # Convenience vocabularies
  class EARL < RDF::Vocabulary("http://www.w3.org/ns/earl#"); end
  class MF < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#"); end

  ##
  # Load test assertions and look for referenced software and developer information
  # @param [Array<String>] *files Assertions
  # @param [Hash{Symbol => Object}] options
  # @option options [Boolean] :verbose (true)
  # @option options [String] :base Base IRI for loading Manifest
  # @option options [String] :bibRef
  #   ReSpec bibliography reference for specification being tested
  # @option options [String] :json Result of previous JSON-LD generation
  # @option options [String, Array<String>] :manifest Test manifest
  # @option options [String] :name Name of specification
  # @option options [String] :query
  #   Query, or file containing query for extracting information from Test manifests
  def initialize(*files)
    @options = files.last.is_a?(Hash) ? files.pop.dup : {}
    @options[:query] ||= MANIFEST_QUERY
    raise "Test Manifests must be specified with :manifest option" unless @options[:manifest] || @options[:json]
    raise "Require at least one input file" if files.empty?
    @files = files
    @prefixes = {}
    if @options[:json]
      @json_hash = ::JSON.parse(File.read(files.first))
      return
    end

    # Load manifests, possibly with base URI
    status "read #{@options[:manifest]}"
    man_opts = {}
    man_opts[:base_uri] = RDF::URI(@options[:base]) if @options[:base]
    @graph = RDF::Graph.new
    [@options[:manifest]].flatten.compact.each do |man|
      g = RDF::Graph.load(man, man_opts)
      status "  loaded #{g.count} triples from #{man}"
      @graph << g
    end

    # Read test assertion files
    files.flatten.each do |file|
      status "read #{file}"
      file_graph = RDF::Graph.load(file)
      status "  loaded #{file_graph.count} triples"
      @graph << file_graph
    end

    # Find or load DOAP descriptions for all subjects
    SPARQL.execute(DOAP_QUERY, @graph).each do |solution|
      subject = solution[:subject]

      # Load DOAP definitions
      unless solution[:name] # not loaded
        status "read doap description for #{subject}"
        begin
          doap_graph = RDF::Graph.load(subject)
          status "  loaded #{doap_graph.count} triples"
          @graph << doap_graph.to_a
        rescue
          status "  failed"
        end
      end
    end

    # Load developers referenced from Test Subjects
    SPARQL.execute(TEST_SUBJECT_QUERY, @graph).each do |solution|
      # Load DOAP definitions
      if solution[:developer] && !solution[:devName] # not loaded
        status "read description for #{solution[:developer].inspect}"
        begin
          foaf_graph = RDF::Graph.load(solution[:developer])
          status "  loaded #{foaf_graph.count} triples"
          @graph << foaf_graph.to_a
        rescue
          status "  failed"
        end
      end
    end
  end
    
  ##
  # Dump the collesced output graph
  #
  # If no `io` option is provided, the output is returned as a string
  #
  # @param [Hash{Symbol => Object}] options
  # @option options [Symbol] format (:html)
  # @option options[IO] :io
  #   Optional `IO` to output results
  # @return [String] serialized graph, if `io` is nil
  def generate(options = {})
    options = {:format => :html}.merge(options)

    io = options[:io]

    status("generate: #{options[:format]}")
    ##
    # Retrieve Hashed information in JSON-LD format
    case options[:format]
    when :jsonld, :json
      json = json_hash.to_json(JSON::LD::JSON_STATE)
      io.write(json) if io
      json
    when :turtle, :ttl
      if io
        earl_turtle(options)
      else
        io = StringIO.new
        earl_turtle(options.merge(:io => io))
        io.rewind
        io.read
      end
    when :html
      template = options[:template] ||
        File.read(File.expand_path('../earl_report/views/earl_report.html.haml', __FILE__))

      # Generate HTML report
      html = Haml::Engine.new(template, :format => :xhtml).render(self, :tests => json_hash)
      io.write(html) if io
      html
    else
      if io
        RDF::Writer.for(options[:format]).new(io) {|w| w << graph}
      else
        graph.dump(options[:format])
      end
    end
  end

  private
  
  ##
  # Return hashed EARL report in JSON-LD form
  # @return [Hash]
  def json_hash
    @json_hash ||= begin
      # Customized JSON-LD output
      {
        "@context" => TEST_CONTEXT,
        "@id"           => "",
        "@type"         => %w(earl:Software doap:Project),
        'name'          => @options[:name],
        'bibRef'        => @options[:bibRef],
        'generatedBy'   => {
          "@id"         => "http://rubygems.org/gems/earl-report",
          "@type"       => "doap:Project",
          "name"        => "earl-report",
          "shortdesc"   => "Earl Report summary generator",
          "doapDesc"    => "EarlReport generates HTML+RDFa rollups of multiple EARL reports",
          "homepage"    => "https://github.com/gkellogg/earl-report",
          "language"    => "Ruby",
          "license"     => "http://unlicense.org",
          "release"     => {
            "@id"       => "https://github.com/gkellogg/earl-report/tree/#{VERSION}",
            "@type"     => "doap:Version",
            "name"      => "earl-report-#{VERSION}",
            "created"   => File.mtime(File.expand_path('../../VERSION', __FILE__)).strftime('%Y-%m-%d'),
            "revision"  => VERSION.to_s
          },
          "developer"   => {
            "@type"     => "foaf:Person",
            "@id"       => "http://greggkellogg.net/foaf#me",
            "foaf:name" => "Gregg Kellogg",
            "foaf:homepage" => "http://greggkellogg.net/"
          }
        },
        "assertions"    => @files,
        'testSubjects'  => json_test_subject_info,
        'entries'        => json_result_info
      }
    end
  end

  ##
  # Return array of test subject information
  # @return [Array]
  def json_test_subject_info
    # Get the set of subjects
    @subject_info ||= begin
      ts_info = {}
      SPARQL.execute(TEST_SUBJECT_QUERY, @graph).each do |solution|
        status "solution #{solution.to_hash.inspect}"
        info = ts_info[solution[:uri].to_s] ||= {}
        %w(name doapDesc homepage language).each do |prop|
          info[prop] = solution[prop.to_sym].to_s if solution[prop.to_sym]
        end
        if solution[:devName]
          dev_type = solution[:devType].to_s =~ /Organization/ ? "foaf:Organization" : "foaf:Person"
          dev = {'@type' => dev_type}
          dev['@id'] = solution[:developer].to_s if solution[:developer].uri?
          dev['foaf:name'] = solution[:devName].to_s if solution[:devName]
          dev['foaf:homepage'] = solution[:devHomepage].to_s if solution[:devHomepage]
          (info['developer'] ||= []) << dev
        end
        info['developer'] = info['developer'].uniq
      end

      # Map ids and values to array entries
      ts_info.keys.sort.map do |id|
        info = ts_info[id]
        subject = Hash.ordered
        subject["@id"] = id
        subject["@type"] = %w(earl:TestSubject doap:Project)
        %w(name developer doapDesc homepage language).each do |prop|
          subject[prop] = info[prop] if info[prop]
        end
        subject
      end
    end
  end

  ##
  # Return result information for each test.
  # This counts on hash maintaining insertion order
  #
  # @return [Array<Hash>] List of manifests
  def json_result_info
    manifests = []
    test_cases = {}
    subjects = json_test_subject_info.map {|s| s['@id']}

    # Hash test cases by URI
    solutions = SPARQL.execute(@options[:query], @graph)
      .to_a
      .inject({}) {|memo, soln| memo[soln[:uri]] = soln; memo}

    # If test cases are in a list, maintain order
    solutions.values.select {|s| s[:manUri]}.each do |man_soln|
      # Get tests for this manifest in list order
      solution_list = RDF::List.new(man_soln[:lh], @graph)

      # Set up basic manifest information
      man_info = manifests.detect {|m| m['@id'] == man_soln[:manUri].to_s}
      unless man_info
        status "manifest: #{man_soln[:manUri]}"
        man_info = {
          '@id' => man_soln[:manUri].to_s,
          "@type" => %w{earl:Report mf:Manifest},
          'title' => man_soln[:manComment].to_s,
          'entries' => []
        }
        manifests << man_info
      end

      # Collect each TestCase
      solution_list.each do |uri|
        solution = solutions[uri]

        # Create entry for this test case, if it doesn't already exist
        tc = man_info['entries'].detect {|t| t['@id'] == uri}
        unless tc
          tc = {
            '@id' => uri.to_s,
            '@type' => %w(earl:TestCriterion earl:TestCase),
            'title' => solution[:title].to_s,
            'testAction' => solution[:testAction].to_s,
            'assertions' => []
          }
          tc['@type'] << solution[:type].to_s if solution[:type]
          tc['description'] = solution[:description].to_s if solution[:description]
          tc['testResult'] = solution[:testResult].to_s if solution[:testResult]
      
          # Pre-initialize results for each subject to untested
          subjects.each do |siri|
            tc['assertions'] << {
              '@type'   => 'earl:Assertion',
              'test'    => uri.to_s,
              'subject' => siri,
              'mode'    => 'earl:automatic',
              'result'  => {
                '@type' => 'earl:TestResult',
                'outcome' => 'earl:untested'
              }
            }
          end

          test_cases[uri.to_s] = tc
          man_info['entries'] << tc
        end
      end

      raise "No test cases found" if man_info['entries'].empty?
      status "Test cases:\n  #{man_info['entries'].map {|tc| tc['@id']}.join("\n  ")}"
    end

    raise "No manifests found" if manifests.empty?
    status "Manifests:\n  #{manifests.map {|m| m['@id']}.join("\n  ")}"

    # Iterate through assertions and add to appropriate test case
    SPARQL.execute(ASSERTION_QUERY, @graph).each do |solution|
      tc = test_cases[solution[:test].to_s]
      STDERR.puts "No test case found for #{solution[:test]}: #{tc.inspect}" unless tc
      subject = solution[:subject].to_s
      result_index = subjects.index(subject)
      ta_hash = tc['assertions'][result_index]
      ta_hash['assertedBy'] = solution[:by].to_s
      ta_hash['mode'] = "earl:#{solution[:mode].to_s.split('#').last || 'automatic'}"
      ta_hash['result']['outcome'] = "earl:#{solution[:outcome].to_s.split('#').last}"
    end

    manifests.sort_by {|m| m['title']}
  end

  ##
  # Output consoloated EARL report as Turtle
  # @param [IO, StringIO] io
  # @return [String]
  def earl_turtle(options)
    io = options[:io]
    # Write preamble
    {
      :dc       => RDF::DC,
      :doap     => RDF::DOAP,
      :earl     => EARL,
      :foaf     => RDF::FOAF,
      :mf       => MF,
      :owl      => RDF::OWL,
      :rdf      => RDF,
      :rdfs     => RDF::RDFS,
      :xhv      => RDF::XHV,
      :xsd      => RDF::XSD
    }.each do |prefix, vocab|
      io.puts("@prefix #{prefix}: <#{vocab.to_uri}> .")
    end
    io.puts

    # Write earl:Software for the report
    man_defs = json_hash['entries'].map {|defn| as_resource(defn['@id'])}.join("\n    ")
    io.puts %{
      #{as_resource(json_hash['@id'])} a #{[json_hash['@type']].flatten.join(', ')};
        doap:name "#{json_hash['name']}";
        dc:bibliographicCitation "#{json_hash['bibRef']}";
        earl:generatedBy #{as_resource json_hash['generatedBy']['@id']};
        earl:assertions
          #{json_hash['assertions'].map {|a| as_resource(a)}.join(",\n          ")};
        earl:testSubjects (
          #{json_hash['testSubjects'].map {|a| as_resource(a['@id'])}.join("\n          ")});
        mf:entries (\n    #{man_defs}) .
    }.gsub(/^      /, '')

    # Write generating software information
    io.puts %{
      <http://rubygems.org/gems/earl-report> a earl:Software, doap:Project;
        doap:name "earl-report";
        doap:shortdesc "Earl Report summary generator"@en;
        doap:description "EarlReport generates HTML+RDFa rollups of multiple EARL reports"@en;
        doap:homepage <https://github.com/gkellogg/earl-report>;
        doap:programming-language "Ruby";
        doap:license <http://unlicense.org>;
        doap:release <https://github.com/gkellogg/earl-report/tree/#{VERSION}>;
        doap:developer <http://greggkellogg.net/foaf#me> .

    }.gsub(/^      /, '')

    # Output Manifest definitions
    # along with test cases and assertions
    test_cases = []
    io.puts %(\n# Manifests)
    json_hash['entries'].each do |man|
      io.puts %(#{as_resource(man['@id'])} a earl:Report, mf:Manifest;)
      io.puts %(  dc:title "#{man['title']}";)
      io.puts %(  mf:name "#{man['title']}";)
      
      # Test Cases
      test_defs = man['entries'].map {|defn| as_resource(defn['@id'])}.join("\n    ")
      io.puts %(  mf:entries (\n    #{test_defs}) .\n\n)

      test_cases += man['entries']
    end

    # Write out each earl:TestSubject
    io.puts %(#\n# Subject Definitions\n#)
    json_hash['testSubjects'].each do |ts_desc|
      io.write(test_subject_turtle(ts_desc))
    end

    # Write out each earl:TestCase
    io.puts %(#\n# Test Case Definitions\n#)
    json_hash['entries'].each do |manifest|
      manifest['entries'].each do |test_case|
        io.write(tc_turtle(test_case))
      end
    end
  end
  
  ##
  # Write out Test Subject definition for each earl:TestSubject
  # @param [Hash] desc
  # @return [String]
  def test_subject_turtle(desc)
    res = %(<#{desc['@id']}> a #{desc['@type'].join(', ')};\n)
    res += %(  doap:name "#{desc['name']}";\n)
    res += %(  doap:description """#{desc['doapDesc']}"""@en;\n)     if desc['doapDesc']
    res += %(  doap:programming-language "#{desc['language']}";\n) if desc['language']
    res += %( .\n\n)

    [desc['developer']].flatten.each do |developer|
      if developer['@id']
        res += %(<#{desc['@id']}> doap:developer <#{developer['@id']}> .\n\n)
        res += %(<#{developer['@id']}> a #{[developer['@type']].flatten.join(', ')};\n)
        res += %(  foaf:homepage <#{developer['foaf:homepage']}>;\n) if developer['foaf:homepage']
        res += %(  foaf:name "#{developer['foaf:name']}" .\n\n)
      else
        res += %(<#{desc['@id']}> doap:developer\n)
        res += %(   [ a #{developer['@type'] || "foaf:Person"};\n)
        res += %(     foaf:homepage <#{developer['foaf:homepage']}>;\n) if developer['foaf:homepage']
        res += %(     foaf:name "#{developer['foaf:name']}" ] .\n\n)
      end
    end
    res + "\n"
  end
  
  ##
  # Write out each Test Case definition
  # @prarm[Hash] desc
  # @return [String]
  def tc_turtle(desc)
    res = %{#{as_resource desc['@id']} a #{[desc['@type']].flatten.join(', ')};\n}
    res += %{  dc:title "#{desc['title']}";\n}
    res += %{  dc:description """#{desc['description']}"""@en;\n} if desc.has_key?('description')
    res += %{  mf:result #{as_resource desc['testResult']};\n} if desc.has_key?('testResult')
    res += %{  mf:action #{as_resource desc['testAction']};\n}
    res += %{  earl:assertions (\n}
    desc['assertions'].each do |as_desc|
      res += as_turtle(as_desc)
    end
    res += %{  ) .\n\n}
  end

  ##
  # Write out each Assertion definition
  # @prarm[Hash] desc
  # @return [String]
  def as_turtle(desc)
    res =  %(    [ a earl:Assertion;\n)
    res += %(      earl:assertedBy #{as_resource desc['assertedBy']};\n) if desc['assertedBy']
    res += %(      earl:test #{as_resource desc['test']};\n)
    res += %(      earl:subject #{as_resource desc['subject']};\n)
    res += %(      earl:mode #{desc['mode']};\n) if desc['mode']
    res += %(      earl:result [ a earl:TestResult; earl:outcome #{desc['result']['outcome']} ]]\n)
  end
  
  def as_resource(resource)
    resource[0,2] == '_:' ? resource : "<#{resource}>"
  end

  def status(message)
    puts message if @options[:verbose]
  end
end
