# EARL reporting
require 'linkeddata'
require 'sparql'
require 'haml'

##
# EARL reporting class.
# Instantiate a new class using one or more input graphs
class EarlReports
  attr_reader :graph
  PROCESSOR_QUERY = %(
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

  ##
  # Load test assertions and look for referenced software and developer information
  # @param [String] manifest Test manifest describe Test Cases
  # @param [Array<String>] files Assertions
  def initialize(manifest, files)
    @graph = RDF::Graph.new
    @prefixes = {}
    [manifest, files].flatten.each do |file|
      puts "read #{file}"
      reader = case file
      when /\.jsonld/
        @json_hash = ::JSON.parse(File.read(file))
        return
      else RDF::Reader.for(file)
      end
      reader.open(file) {|r| @graph << r}
    end

    # Find or load DOAP descriptions for all subjects
    SPARQL.execute(DOAP_QUERY, @graph).each do |solution|
      subject = solution[:subject]

      # Load DOAP definitions
      unless solution[:name] # not loaded
        puts "read doap description for #{subject}"
        begin
          doap_graph = RDF::Graph.load(subject)
          puts "  read #{doap_graph.count} triples"
          @graph << doap_graph.to_a
        rescue
          puts "  failed"
        end
      end
    end

    # Load developers referenced from Test Subjects
    SPARQL.execute(PROCESSOR_QUERY, @graph).each do |solution|
      # Load DOAP definitions
      if solution[:developer] && !solution[:dev_name] # not loaded
        puts "read description for #{solution[:developer].inspect}"
        begin
          foaf_graph = RDF::Graph.load(solution[:developer])
          puts "  read #{foaf_graph.count} triples"
          @graph << foaf_graph.to_a
        rescue
          puts "  failed"
        end
      end
    end
  end
    
  ##
  # Dump the collesced output graph
  #
  # If no `io` parameter is provided, the output is returned as a string
  #
  # @param [Symbol] format
  # @param [String] bibRef (nil)
  #   ReSpec formatted bib ref for software being reported
  # @param [IO] io (nil)
  # @return [String] serialized graph, if `io` is nil
  def dump(format, bibRef = nil, io = nil)
    @bibRef = bibRef || "No reference provided"
    options = {
      :standard_prefixes => true,
      :prefixes => { :earl => "http://www.w3.org/ns/earl#", }
    }

    ##
    # Retrieve Hashed information in JSON-LD format
    case format
    when :jsonld
      json = json_hash(options).to_json(JSON::LD::JSON_STATE)
      io.write(json) if io
      json
    when :turtle, :ttl
      if io
        earl_turtle(io)
      else
        io = StringIO.new
        earl_turtle(io)
        io.rewind
        io.read
      end
    else
      if io
        RDF::Writer.for(format).new(io) {|w| w << graph}
      else
        graph.dump(format)
      end
    end
  end

  ##
  # Generate output report, using Haml template
  # If no `io` parameter is provided, the output is returned as a string
  #
  # @param [IO, String, Hash] json
  # @param [Array<String>] source_files
  # @param [IO] io (nil)
  # @return [String] Generated report, if `io` is nil
  def self.generate(json, source_files, io = nil)
    json = json.read if json.respond_to?(:read)
    tests = json.is_a?(String) ? ::JSON.parse(json) : json

    template = File.read(File.expand_path('../views/earl_report.html.haml', __FILE__))

    html = Haml::Engine.new(template, :format => :xhtml).render(self, {:tests => tests, :source_files => source_files})
    io.write(html) if io
    html
  end
  
  private
  
  ##
  # Return hashed EARL reports in JSON-LD form
  # @return [Hash]
  def json_hash
    @json_hash ||= begin
      # Customized JSON-LD output
      hash = Hash.ordered
      hash["@context"] = {
        dc:           "http://purl.org/dc/terms/",
        doap:         "http://usefulinc.com/ns/doap#",
        earl:         "http://www.w3.org/ns/earl#",
        foaf:         "http://xmlns.com/foaf/0.1/",
        rdfs:         "http://www.w3.org/2000/01/rdf-schema#",
        assertedBy:   {"@id" => "earl:assertedBy", "@type" => "@id"},
        bibRef:       {"@id" => "dc: bibliographicCitation"},
        description:  {"@id" => "dc:description"},
        developer:    {"@id" => "doap:developer", "@type" => "@id"},
        homepage:     {"@id" => "doap:homepage", "@type" => "@id"},
        doap_desc:    {"@id" => "doap:description"},
        language:     {"@id" => "doap:programming-language"},
        label:        {"@id" => "rdfs:label"},
        mode:         {"@id" => "earl:mode", "@type" => "@id"},
        name:         {"@id" => "doap:name"},
        outcome:      {"@id" => "earl:outcome", "@type" => "@id"},
        result:       {"@id" => "earl:result"},
        subject:      {"@id" => "earl:subject", "@type" => "@id"},
        test:         {"@id" => "earl:test", "@type" => "@id"},
        title:        {"@id" => "dc:title"}
      }
      hash["@type"] = %w(earl:Software doap:Project)
      hash['name'] = "RDFa Test Suite"
      hash['bibRef'] = @bibRef
      hash['subjects'] = json_subject_info
      hash.merge!(json_result_info)
    end
  end

  ##
  # Return array of processor information
  # @return [Array]
  def json_subject_info
    # Get the set of processors
    proc_info = {}
    SPARQL.execute(PROCESSOR_QUERY, @graph).each do |solution|
      puts "solution #{solution.to_hash.inspect}"
      info = proc_info[solution[:uri].to_s] ||= {}
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
    proc_info.keys.map do |id|
      info = proc_info[id]
      processor = Hash.ordered
      processor["@id"] = id
      processor["@type"] = %w(earl:TestSubject doap:Project)
      %w(name developer doap_desc homepage language).each do |prop|
        processor[prop] = info[prop] if info[prop]
      end
      processor
    end
  end
  
  ##
  # Return result information as version/host-language
  # @return [Hash]
  def json_result_info
    hash = Hash.ordered
    test_cases = {}

    # Get versions and hostLanguages
    @graph.query(:subject => RDF::URI(SUITE_URI)).each do |version_stmt|
      if version_stmt.predicate.to_s.index(RDFATEST["version/"]) == 0
        # This is a version predicate, it includes hostLanguage predicates
        vers = version_stmt.predicate.to_s.sub(RDFATEST["version/"].to_s, '')
        version = hash[vers] ||= begin
          vh = Hash.ordered
          vh['@type'] = "rdfatest:Version"
          puts "version: #{vers}"
          vh
        end
        
        @graph.query(:subject => version_stmt.object).each do |hl_stmt|
          if hl_stmt.predicate.to_s.index(RDFATEST["hostLanguage/"]) == 0
            # This is a hostLanguage predicate, it includes hostLanguage predicates
            hl = hl_stmt.predicate.to_s.sub(RDFATEST["hostLanguage/"].to_s, '')
            next if version.has_key?(hl)
            puts "hostLanguage: #{hl}"
            version[hl] = []
            
            # Iterate though the list and append ordered test assertion
            RDF::List.new(hl_stmt.object, @graph).each do |tc|
              tc_hash = Hash.ordered
              tc_hash['@id'] = tc.to_s
              tc_hash['@type'] = "earl:TestCase"
              test_cases[tc.to_s] = tc_hash
              
              # Extract important properties
              title = description = nil
              @graph.query(:subject => tc).each do |tc_stmt|
                case tc_stmt.predicate.to_s
                when RDF::DC.title.to_s
                  title = tc_stmt.object.to_s
                when RDF::DC.description.to_s
                  description = tc_stmt.object.to_s
                when EARL.mode.to_s, RDF.type.to_s
                  # Skip this
                end
              end

              tc_hash['num'] = tc.to_s.split('/').last.split('.').first
              tc_hash['title'] = title
              tc_hash['description'] = description unless description.empty?

              version[hl] << tc_hash
            end
          end
        end
      end
    end

    # Iterate through assertions and add to appropriate test case
    SPARQL.execute(ASSERTION_QUERY, @graph).each do |solution|
      tc = test_cases[solution[:test].to_s]
      raise "No test case found for #{solution[:test]}" unless tc
      tc ||= {}
      processor = solution[:subject].to_s
      result_hash = Hash.ordered
      result_hash['@type'] = 'earl:TestResult'
      result_hash['outcome'] = solution[:outcome] == EARL.passed ? 'earl:passed' : 'earl:failed'
      ta_hash = Hash.ordered
      ta_hash['@type'] = 'earl:Assertion'
      ta_hash['assertedBy'] = SUITE_URI
      ta_hash['test'] = solution[:test].to_s
      ta_hash['mode'] = "earl:#{solution[:mode].to_s.split('#').last || 'automatic'}"
      ta_hash['subject'] = processor
      ta_hash['result'] = result_hash
      tc[processor] = ta_hash
    end

    hash
  end
  
  ##
  # Output consoloated EARL report as Turtle
  # @param [IO, StringIO] io
  # @return [String]
  def earl_turtle(io)
    # Write preamble
    {
      :dc       => RDF::DC,
      :doap     => RDF::DOAP,
      :earl     => ::EARL::EARL,
      :foaf     => RDF::FOAF,
      :owl      => RDF::OWL,
      :rdf      => RDF,
      :rdfa     => RDF::RDFA,
      :rdfatest => RDFATEST,
      :rdfs     => RDF::RDFS,
      :xhv      => RDF::XHV,
      :xsd      => RDF::XSD
    }.each do |prefix, vocab|
      io.puts("@prefix #{prefix}: <#{vocab.to_uri}> .")
    end
    io.puts
    
    # Write earl:Software
    io.puts %(<#{json_hash['@id']}> a earl:Softare, doap:Project;)
    io.puts %(  doap:homepage <#{json_hash['homepage']}>;)
    io.puts %(  doap:name "#{json_hash['homepage']}";)
    
    # Processors
    proc_defs = json_hash['processor'].map {|proc_def| "<#{proc_def['@id']}>"}.join(",\n    ")
    io.puts %(  rdfa:processor #{proc_defs};)
    
    # Versions
    # also collect test case definitions
    # also collect each assertion definition
    test_cases = {}
    assertions = []
    json_hash.keys.select {|k| k =~ /rdfa\d\.*/}.each do |version|
      io.puts %(  <http://rdfa.info/vocabs/rdfa-test#version/#{version}> [ a rdfatest:Version;)
      
      # Host Languages
      json_hash[version].keys.reject {|k| k == '@type'}.each do |host_language|
        io.puts "    <http://rdfa.info/vocabs/rdfa-test#hostLanguage/#{host_language}> ("
        
        # Tests
        json_hash[version][host_language].each do |test_case|
          tc_desc =  test_cases[test_case['num']] ||= test_case.merge({'hostLanguage' => [], 'version' => []})
          tc_desc['version'] << version
          tc_desc['hostLanguage'] << host_language
          test_case.keys.select {|k| k =~ /^http:/}.each do |proc_uri|
            tc_desc[proc_uri] = test_case[proc_uri]['@id']
            assertions << test_case[proc_uri]
          end
          io.puts %(      <#{test_case['@id']}>)
        end
        io.puts "    ),"
      end
      io.puts %(  ];)
    end
    io.puts %(  .\n)
    
    # Write out each earl:TestSubject
    io.puts %(#\n# Processor Definitions\n#)
    json_hash['processor'].each do |proc_desc|
      io.write(proc_turtle(proc_desc))
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
  # Write out Processor definition for each earl:TestSubject
  # @param [Hash] desc
  # @return [String]
  def proc_turtle(desc)
    developer = desc['developer']
    res = %(<#{desc['@id']}> a #{desc['@type'].join(', ')}\n)
    res += %(  doap:name "#{desc['name']}";\n)
    res += %(  doap:description """#{desc['doap_desc']}""";\n)     if desc['doap_desc']
    res += %(  doap:programming-language "#{desc['language']}";\n) if desc['language']
    if developer && developer['@id']
      res += %(  doap:developer <#{developer['@id']}> .\n)
      res += %(<#{developer['@id']}> a #{[developer['@type']].flatten.join(', ')} )
      res += %(foaf:name "#{developer['foaf:name']}" .\n)
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
    res += %(  rdfatest:num "#{desc['num']}";\n)
    res += %(  rdfatest:rdfaVersion #{desc['version'].sort.uniq.map(&:dump).join(', ')};\n)
    res += %(  rdfatest:hostLanguage #{desc['hostLanguage'].sort.uniq.map(&:dump).join(', ')}.\n)
    res + "\n"
  end

  ##
  # Write out each Assertion definition
  # @prarm[Hash] desc
  # @return [String]
  def as_turtle(desc)
    res =  %([ a earl:Assertion\n)
    res += %(  earl:assertedBy <#{desc['assertedBy']}>;\n)
    res += %(  earl:test <#{desc['test']}>;\n)
    res += %(  earl:subject <#{desc['subject']}>;\n)
    res += %(  earl:mode #{desc['mode']};\n)
    res += %(  earl:result [ a earl:Result; #{desc['result']['outcome']}] ] .\n)
    res += %(\n)
    res
  end
end
