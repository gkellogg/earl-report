# EARL reporting
require 'linkeddata'
require 'sparql'
require 'haml'

##
# EARL reporting class.
# Instantiate a new class using one or more input graphs
class EarlReport
  attr_reader :graph
  TEST_SUBJECT_QUERY = %(
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    
    SELECT DISTINCT ?uri ?name ?developer ?dev_name ?dev_type ?doap_desc ?homepage ?language
    WHERE {
      ?uri a doap:Project; doap:name ?name .
      OPTIONAL { ?uri doap:developer ?developer .}
      OPTIONAL { ?uri doap:homepage ?homepage . }
      OPTIONAL { ?uri doap:description ?doap_desc . }
      OPTIONAL { ?uri doap:programming-language ?language . }
      OPTIONAL { ?developer foaf:name ?dev_name .}
      OPTIONAL { ?developer a ?dev_type . }
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
  )

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
  ).freeze

  # Convenience vocabularies
  class EARL < RDF::Vocabulary("http://www.w3.org/ns/earl#"); end
  class MF < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#"); end

  ##
  # Load test assertions and look for referenced software and developer information
  # @param [Array<String>] *files Assertions
  # @param [Hash{Symbol => Object}] options
  # @option options [Boolean] :verbose (true)
  def initialize(*files)
    @options = files.last.is_a?(Hash) ? files.pop.dup : {}
    @graph = RDF::Graph.new
    @prefixes = {}
    files.flatten.each do |file|
      status "read #{file}"
      file_graph = case file
      when /\.jsonld/
        @json_hash = ::JSON.parse(File.read(file))
        return
      else RDF::Graph.load(file)
      end
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
      if solution[:developer] && !solution[:dev_name] # not loaded
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
  # @option options [String] :bibRef
  #   ReSpec bibliography reference for specification being tested
  # @option options [String] :name
  # @option options [String] :shortName
  # @option options [String] :subTitle
  # @option options [Array{Hash}, Hash] :editors
  #   Editor has in ReSpec format.
  # @option options [String] :wg
  # @option options [String] :wgURI
  # @option options [String] :wgPublicList
  # @option options [String] :wgPatentURI
  # @option options[IO] :io
  #   Optional `IO` to output results
  # @return [String] serialized graph, if `io` is nil
  def generate(options = {})
    options = {
      format:       :html,
      bibRef:       "[[TURTLE]]",
      name:         "Turtle Test Results",
      shortName:    "turtle-earl",
      subTitle:     "Report on Test Subject Conformance for Turtle",
      editors:      {
                      name: "Gregg Kellogg",
                      url: "http://greggkellogg.net/",
                      company: "Kellogg Associates",
                      companyURL: "http://kellogg-assoc.com/"
                    },
      wg:           "RDF Working Group",
      wgURI:        "http://www.w3.org/2011/rdf-wg/",
      wgPublicList: "public-rdf-comments",
      wgPatentURI:  "http://www.w3.org/2004/01/pp-impl/46168/status",
    }.merge(options)

    io = options[:io]

    status("generate: #{options[:format]}")
    ##
    # Retrieve Hashed information in JSON-LD format
    hash = json_hash(options)
    case options[:format]
    when :jsonld, :json
      json = hash.to_json(JSON::LD::JSON_STATE)
      io.write(json) if io
      json
    when :turtle, :ttl
      if io
        earl_turtle(options.merge(:json_hash => hash))
      else
        io = StringIO.new
        earl_turtle(:json_hash => hash, :io => io)
        io.rewind
        io.read
      end
    when :html
      template = File.read(File.expand_path('../views/earl_report.html.haml', __FILE__))

      # Generate HTML report
      # FIXME: read source files
      html = Haml::Engine.new(template, :format => :xhtml)
        .render(self, :tests => hash, :source_files => [])
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
  def json_hash(options)
    @json_hash ||= begin
      # Customized JSON-LD output
      {
        "@context" => {
          dc:           "http://purl.org/dc/terms/",
          doap:         "http://usefulinc.com/ns/doap#",
          earl:         "http://www.w3.org/ns/earl#",
          mf:           "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
          foaf:         "http://xmlns.com/foaf/0.1/",
          rdfs:         "http://www.w3.org/2000/01/rdf-schema#",
          assertedBy:   {"@id" => "earl:assertedBy", "@type" => "@id"},
          bibRef:       {"@id" => "dc: bibliographicCitation"},
          description:  {"@id" => "dc:description"},
          developer:    {"@id" => "doap:developer", "@type" => "@id"},
          homepage:     {"@id" => "doap:homepage", "@type" => "@id"},
          doap_desc:    {"@id" => "doap:description"},
          language:     {"@id" => "doap:programming-language"},
          testAction:   {"@id" => "mf:action", "@type" => "@id"},
          testResult:   {"@id" => "mf:result", "@type" => "@id"},
          label:        {"@id" => "rdfs:label"},
          mode:         {"@id" => "earl:mode", "@type" => "@id"},
          name:         {"@id" => "doap:name"},
          outcome:      {"@id" => "earl:outcome", "@type" => "@id"},
          result:       {"@id" => "earl:result"},
          subject:      {"@id" => "earl:subject", "@type" => "@id"},
          test:         {"@id" => "earl:test", "@type" => "@id"},
          title:        {"@id" => "dc:title"}
        },
        "@id"          => "",
        "@type"        => %w(earl:Software doap:Project),
        'name'         => options[:name],
        'bibRef'       => options[:bibRef],
        'testSubjects' => json_test_subject_info,
        'tests'        => json_result_info
      }
    end
  end

  ##
  # Return array of test subject information
  # @return [Array]
  def json_test_subject_info
    # Get the set of subjects
    ts_info = {}
    SPARQL.execute(TEST_SUBJECT_QUERY, @graph).each do |solution|
      status "solution #{solution.to_hash.inspect}"
      info = ts_info[solution[:uri].to_s] ||= {}
      %w(name doap_desc homepage language).each do |prop|
        info[prop] = solution[prop.to_sym].to_s if solution[prop.to_sym]
      end
      if solution[:dev_name]
        dev_type = solution[:dev_type].to_s =~ /Organization/ ? "foaf:Organization" : "foaf:Person"
        info['developer'] = Hash.ordered
        info['developer']['@id'] = solution[:developer].to_s if solution[:developer].uri?
        info['developer']['@type'] = dev_type
        info['developer']['foaf:name'] = solution[:dev_name].to_s if solution[:dev_name]
      end
    end

    # Map ids and values to array entries
    ts_info.keys.map do |id|
      info = ts_info[id]
      subject = Hash.ordered
      subject["@id"] = id
      subject["@type"] = %w(earl:TestSubject doap:Project)
      %w(name developer doap_desc homepage language).each do |prop|
        subject[prop] = info[prop] if info[prop]
      end
      subject
    end
  end
  
  ##
  # Return result information for each test
  #
  # @return [Array]
  def json_result_info
    test_cases = {}

    @graph.query(:predicate => MF['entries']) do |stmt|
      # Iterate through the test manifest and write out a TestCase
      # for each test
      RDF::List.new(stmt.object, @graph).map do |tc|
        tc_hash = {}
        tc_hash['@id'] = tc.to_s
        tc_hash['@type'] = %w(earl:TestCriterion earl:TestCase)

        # Extract important properties
        @graph.query(:subject => tc).each do |tc_stmt|
          case tc_stmt.predicate.to_s
          when MF['name'].to_s
            tc_hash['title'] = tc_stmt.object.to_s
          when RDF::RDFS.comment.to_s
            tc_hash['description'] = tc_stmt.object.to_s
          when MF.action.to_s
            tc_hash['testAction'] = tc_stmt.object.to_s
          when MF.result.to_s
            tc_hash['testResult'] = tc_stmt.object.to_s
          else
            #STDERR.puts "TC soln: #{tc_stmt.inspect}"
          end
        end

        test_cases[tc.to_s] = tc_hash
      end
    end

    raise "No test cases found" if test_cases.empty?

    status "Test cases:\n  #{test_cases.keys.join("\n  ")}"
    # Iterate through assertions and add to appropriate test case
    SPARQL.execute(ASSERTION_QUERY, @graph).each do |solution|
      tc = test_cases[solution[:test].to_s]
      STDERR.puts "No test case found for #{solution[:test]}" unless tc
      tc ||= {}
      subject = solution[:subject].to_s
      ta_hash = {}
      ta_hash['@type'] = 'earl:Assertion'
      ta_hash['assertedBy'] = solution[:by].to_s
      ta_hash['test'] = solution[:test].to_s
      ta_hash['mode'] = "earl:#{solution[:mode].to_s.split('#').last || 'automatic'}"
      ta_hash['subject'] = subject
      ta_hash['result'] = {
        '@type' => 'earl:TestResult',
        "outcome" => (solution[:outcome] == EARL.passed ? 'earl:passed' : 'earl:failed')
      }
      tc[subject] = ta_hash
    end

    test_cases.values
  end
  
  ##
  # Output consoloated EARL report as Turtle
  # @param [IO, StringIO] io
  # @return [String]
  def earl_turtle(options)
    io = options[:io]
    json_hash = options[:json_hash]
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
    io.puts %(<#{json_hash['@id']}> a earl:Software, doap:Project;)
    io.puts %(  doap:homepage <#{json_hash['homepage']}>;)
    io.puts %(  doap:name "#{json_hash['name']}".)

    # Test Cases
    # also collect each assertion definition
    test_cases = {}
    assertions = []

    # Tests
    json_hash['tests'].each do |test_case|
      tc_desc =  test_cases[test_case['test']] ||= test_case.dup
      test_case.keys.select {|k| k =~ /^http:/}.each do |ts_uri|
        tc_desc[ts_uri] = test_case[ts_uri]['@id']
        assertions << test_case[ts_uri]
      end
    end
    
    # Write out each earl:TestSubject
    io.puts %(#\n# Subject Definitions\n#)
    json_hash['testSubjects'].each do |ts_desc|
      io.write(test_subject_turtle(ts_desc))
    end
    
    # Write out each earl:TestCase
    io.puts %(#\n# Test Case Definitions\n#)
    test_cases.keys.sort.each do |num|
      io.write(tc_turtle(test_cases[num]))
    end
    
    # Write out each earl:Assertion
    io.puts %(#\n# Assertions\n#)
    assertions.sort_by {|a| a['@id']}.each do |as_desc|
      io.write(as_turtle(as_desc))
    end
  end
  
  ##
  # Write out Test Subject definition for each earl:TestSubject
  # @param [Hash] desc
  # @return [String]
  def test_subject_turtle(desc)
    developer = desc['developer']
    res = %(<#{desc['@id']}> a #{desc['@type'].join(', ')};\n)
    res += %(  doap:name "#{desc['name']}";\n)
    res += %(  doap:description """#{desc['doap_desc']}""";\n)     if desc['doap_desc']
    res += %(  doap:programming-language "#{desc['language']}";\n) if desc['language']
    if developer && developer['@id']
      res += %(  doap:developer <#{developer['@id']}> .\n\n)
      res += %(<#{developer['@id']}> a #{[developer['@type']].flatten.join(', ')};\n)
      res += %(  foaf:name "#{developer['foaf:name']}" .\n)
    elsif developer
      res += %(  doap:developer [ a #{developer['@type'] || "foaf:Person"}; foaf:name "#{developer['foaf:name']}"] .\n)
    else
      res += %(  .\n)
    end
    res + "\n"
  end
  
  ##
  # Write out each Test Case definition
  # @prarm[Hash] desc
  # @return [String]
  def tc_turtle(desc)
    res = %(<#{desc['@id']}> a #{[desc['@type']].flatten.join(', ')};\n)
    res += %(  dc:title "#{desc['title']}";\n)
    res += %(  dc:description """#{desc['description']}""";\n)
    res += %(  mf:action <#{desc['testAction']}>;\n)
    res += %(  mf:result <#{desc['testResult']}>;\n)
    res + "\n"
  end

  ##
  # Write out each Assertion definition
  # @prarm[Hash] desc
  # @return [String]
  def as_turtle(desc)
    res =  %([ a earl:Assertion;\n)
    res += %(  earl:assertedBy <#{desc['assertedBy']}>;\n)
    res += %(  earl:test <#{desc['test']}>;\n)
    res += %(  earl:subject <#{desc['subject']}>;\n)
    res += %(  earl:mode #{desc['mode']};\n)
    res += %(  earl:result [ a earl:TestResult; earl:outcome #{desc['result']['outcome']}] ] .\n)
    res += %(\n)
    res
  end
  
  def status(message)
    puts message if @options[:verbose]
  end
end
