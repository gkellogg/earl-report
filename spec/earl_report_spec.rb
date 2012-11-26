# coding: utf-8
$:.unshift "."
require 'spec_helper'

describe EarlReport do
  subject {
    EarlReport.new(
      File.expand_path("../test-files/report-complete.ttl", __FILE__),
      :bibRef   =>       "[[TURTLE]]",
      :name     =>         "Turtle Test Results",
      :verbose  => false,
      :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
  }

  describe ".new" do
    let(:manifest) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/manifest.ttl", __FILE__))
    }
    let(:reportComplete) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/report-complete.ttl", __FILE__))
    }
    let(:reportNoDoap) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/report-no-doap.ttl", __FILE__))
    }
    let(:reportNoFoaf) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/report-no-foaf.ttl", __FILE__))
    }
    let(:doap) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/doap.ttl", __FILE__))
    }
    let(:foaf) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/foaf.ttl", __FILE__))
    }

    it "requires a :manifest option" do
      lambda {EarlReport.new}.should raise_error("Test Manifest must be specified with :manifest option")
    end

    context "with base" do
      it "loads manifest relative to base" do
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {:base_uri => "http://example.com/base/"})
          .and_return(manifest)
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/report-complete.ttl", __FILE__))
          .and_return(reportComplete)
        EarlReport.new(
          File.expand_path("../test-files/report-complete.ttl", __FILE__),
          :verbose => false,
          :base => "http://example.com/base/",
          :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
      end
    end

    context "complete report" do
      before(:each) do
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {})
          .and_return(manifest)
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/report-complete.ttl", __FILE__))
          .and_return(reportComplete)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-complete.ttl", __FILE__),
          :verbose => false,
          :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl"))
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        subject.graph.predicates.to_a.should include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        subject.graph.objects.to_a.should include(RDF::FOAF.Person)
      end
    end

    context "no doap report" do
      before(:each) do
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {})
          .and_return(manifest)
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/report-no-doap.ttl", __FILE__))
          .and_return(reportNoDoap)
        RDF::Graph.should_receive(:load)
          .with("http://rubygems.org/gems/rdf-turtle")
          .and_return(doap)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-no-doap.ttl", __FILE__),
          :verbose => false,
          :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl"))
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        subject.graph.predicates.to_a.should include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        subject.graph.objects.to_a.should include(RDF::FOAF.Person)
      end
    end

    context "no foaf report" do
      before(:each) do
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {})
          .and_return(manifest)
        RDF::Graph.should_receive(:load)
          .with(File.expand_path("../test-files/report-no-foaf.ttl", __FILE__))
          .and_return(reportNoFoaf)
        RDF::Graph.should_receive(:load)
          .with("http://greggkellogg.net/foaf#me")
          .and_return(foaf)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-no-foaf.ttl", __FILE__),
          :verbose => false,
          :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl"))
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        subject.graph.predicates.to_a.should include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        subject.graph.objects.to_a.should include(RDF::FOAF.Person)
      end
    end
  end
  
  describe "#json_hash" do
    let(:json) {
      subject.send(:json_hash)
    }
    specify {json.should be_a(Hash)}
    {
      "@id"    => "",
      "@type"  => "earl:Report",
      'bibRef' => "[[TURTLE]]",
      'title'   => "Turtle Test Results"
    }.each do |prop, value|
      specify(prop) {json[prop].should == value}
    end

    %w(assertions generatedBy testSubjects tests).each do |key|
      specify {json.keys.should include(key)}
    end

    context "parsing to RDF" do
      let(:graph) do
        @graph ||= begin
          RDF::Graph.new << JSON::LD::Reader.new(json.to_json, :base_uri => "http://example.com/report")
        end
      end

      it "has Report" do
        SPARQL.execute(REPORT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Subject" do
        SPARQL.execute(SUBJECT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Developer" do
        SPARQL.execute(DEVELOPER_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Test Case" do
        SPARQL.execute(TC_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Assertion" do
        SPARQL.execute(ASSERTION_QUERY, graph).should be_true
      end
    end
  end
  
  describe "#json_test_subject_info" do
    let(:json) {subject.send(:json_test_subject_info)}
    specify {json.should be_a(Array)}
    specify("have length 1") {json.length.should == 1}

    context "test subject" do
      let(:ts) {json.first}
      {
        "@id" =>  "http://rubygems.org/gems/rdf-turtle",
        "@type" =>  %w(earl:TestSubject doap:Project),
        doapDesc:   "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite.",
        homepage:   "http://ruby-rdf.github.com/rdf-turtle",
        language:   "Ruby",
        name:       "RDF::Turtle",
      }.each do |prop, value|
        specify(prop) {ts[prop.to_s].should == value}
      end
      
      context "developer" do
        let(:dev) {ts['developer']}
        specify {dev.should be_a(Array)}
        specify {dev.first.should be_a(Hash)}
        {
          "@id"       => "http://greggkellogg.net/foaf#me",
          "@type"     => %(foaf:Person),
          "foaf:name" => "Gregg Kellogg",
        }.each do |prop, value|
          specify(prop) {dev.first[prop.to_s].should == value}
        end
      end
    end
  end
  
  describe "#json_result_info" do
    let(:json) {subject.send(:json_result_info)}
    specify {json.should be_a(Array)}
    specify("have 2 entries") {json.length.should == 2}

    context "test case" do
      let(:tc) {json.first}
      {
        "@id" =>      "http://example/manifest.ttl#testeval00",
        "@type" =>    %w(earl:TestCriterion earl:TestCase),
        title:         "subm-test-00",
        description:  "Blank subject",
        testAction:   "http://example/test-00.ttl",
        testResult:   "http://example/test-00.out",
      }.each do |prop, value|
        specify(prop) {tc[prop.to_s].should == value}
      end

      context('assertions') do
        specify { tc['assertions'].should be_a(Array)}
        specify('has one entry') { tc['assertions'].length.should == 1}
      end

      context "assertion" do
        let(:as) {tc['assertions'].first}
        specify {as.should be_a(Hash)}
        {
          "@type" =>  %(earl:Assertion),
          assertedBy: "http://greggkellogg.net/foaf#me",
          mode:       "earl:automatic",
          subject:    "http://rubygems.org/gems/rdf-turtle",
          test:       "http://example/manifest.ttl#testeval00",
        }.each do |prop, value|
          specify(prop) {as[prop.to_s].should == value}
        end

        context "result" do
          let(:rs) {as['result']}
          specify {rs.should be_a(Hash)}
          {
            "@type" =>  %(earl:TestResult),
            outcome:    "earl:passed",
          }.each do |prop, value|
            specify(prop) {rs[prop.to_s].should == value}
          end
        end
      end
    end
  end

  describe "#test_subject_turtle" do
    context "test subject" do
      let(:desc) {{
        "@id"       => "http://rubygems.org/gems/rdf-turtle",
        "@type"     => %w(earl:TestSubject doap:Project),
        'doapDesc'  => "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite.",
        'homepage'  => "http://ruby-rdf.github.com/rdf-turtle",
        'language'  => "Ruby",
        'name'      => "RDF::Turtle",
        'developer' => {
          '@id'       => "http://greggkellogg.net/foaf#me",
          '@type'     => %w(foaf:Person earl:Assertor),
          'foaf:name' => "Gregg Kellogg"
        }
      }}
      let(:ttl) {subject.send(:test_subject_turtle, desc)}
      specify {ttl.length.should > 0}
      it "has subject subject" do
        ttl.should match(/<#{desc['@id']}> a/)
      end
      it "has types" do
        ttl.should match(/ a #{desc['@type'].join(', ')}\s*[;\.]$/)
      end
      it "has name" do
        ttl.should match(/ doap:name "#{desc['name']}"\s*[;\.]$/)
      end
      it "has description" do
        ttl.should match(/ doap:description """#{desc['doapDesc']}"""@en\s*[;\.]$/)
      end
      it "has doap:programming-language" do
        ttl.should match(/ doap:programming-language "#{desc['language']}"\s*[;\.]$/)
      end
      it "has doap:developer" do
        ttl.should match(/ doap:developer <#{desc['developer']['@id']}>/)
      end
      
      context "developer" do
        let(:dev) {desc['developer']}
        it "has subject subject" do
          ttl.should match(/<#{dev['@id']}> a/)
        end
        it "has types" do
          ttl.should match(/ a #{dev['@type'].join(', ')}\s*[;\.]$/)
        end
        it "has name" do
          ttl.should match(/ foaf:name "#{dev['foaf:name']}"\s*[;\.]$/)
        end
      end
    end
  end

  describe "#tc_turtle" do
    context "test case" do
      let(:tc) {{
        "@id"         => "http://example/manifest.ttl#testeval00",
        "@type"       => %w(earl:TestCriterion earl:TestCase),
        'title'       => "subm-test-00",
        'description' => "Blank subject",
        'testAction'  => "http://example/test-00.ttl",
        'testResult'  => "http://example/test-00.out",
        'assertions'  => [{
          "@type"      =>  %(earl:Assertion),
          'assertedBy' =>"http://greggkellogg.net/foaf#me",
          'mode'       => "earl:automatic",
          'subject'    => "http://rubygems.org/gems/rdf-turtle",
          'test'       => "http://example/manifest.ttl#testeval00",
          'result'     => {
            "@type"    => %(earl:TestResult),
            'outcome'  => "earl:passed",
          }
        }]
      }}
      let(:ttl) {subject.send(:tc_turtle, tc)}
      specify {ttl.length.should > 0}
      it "has subject subject" do
        ttl.should match(/<#{tc['@id']}> a/)
      end
      it "has types" do
        ttl.should match(/ a #{tc['@type'].join(', ')}\s*[;\.]$/)
      end
      it "has dc:title" do
        ttl.should match(/ dc:title "#{tc['title']}"\s*[;\.]$/)
      end
      it "has dc:description" do
        ttl.should match(/ dc:description """#{tc['description']}"""@en\s*[;\.]$/)
      end
      it "has mf:action" do
        ttl.should match(/ mf:action <#{tc['testAction']}>\s*[;\.]$/)
      end
      it "has mf:result" do
        ttl.should match(/ mf:result <#{tc['testResult']}>\s*[;\.]$/)
      end
      it "has earl:assertions" do
        ttl.should match(/ earl:assertions \(\s*\[ a earl:Assertion/m)
      end
    end
  end

  describe "#as_turtle" do
    context "assertion" do
      let(:as) {{
        "@type"      =>  %w(earl:Assertion),
        'assertedBy' => "http://greggkellogg.net/foaf#me",
        'mode'       => "earl:automatic",
        'subject'    => "http://rubygems.org/gems/rdf-turtle",
        'test'       => "http://example/manifest.ttl#testeval00",
        'result'     => {
          '@type'    => 'earl:TestResult',
          'outcome'  => 'earl:passed'
        }
      }}
      let(:ttl) {subject.send(:as_turtle, as)}
      specify {ttl.length.should > 0}
      it "has type" do
        ttl.should match(/ a #{as['@type'].join(', ')}\s*[;\.]$/)
      end
      it "has earl:assertedBy" do
        ttl.should match(/ earl:assertedBy <#{as['assertedBy']}>\s*[;\.]$/)
      end
      it "has earl:test" do
        ttl.should match(/ earl:test <#{as['test']}>\s*[;\.]$/)
      end
      it "has earl:subject" do
        ttl.should match(/ earl:subject <#{as['subject']}>\s*[;\.]$/)
      end
      it "has earl:mode" do
        ttl.should match(/ earl:mode #{as['mode']}\s*[;\.]$/)
      end
      it "has earl:result" do
        ttl.should match(/ earl:result \[ a #{as['result']['@type']}; earl:outcome #{as['result']['outcome']} \]\]/)
      end
    end
  end

  describe "#earl_turtle" do
    let(:json_hash) {subject.send(:json_hash)}
    let(:output) {
      @output ||= begin
        sio = StringIO.new
        subject.send(:earl_turtle, {io: sio})
        sio.rewind
        sio.read
      end
    }
    let(:ts) {json_hash['testSubjects'].first}
    let(:tc) {json_hash['tests'].first}
    let(:as) {tc['assertions'].first}

    context "prefixes" do
      %w(dc doap earl foaf mf owl rdf rdfs xsd).each do |pfx|
        it "should have prefix #{pfx}" do
          output.should match(/@prefix #{pfx}: </)
        end
      end
    end

    context "earl:Software" do
      specify {output.should match(/<> a earl:Report\s*[;\.]$/)}
      specify {output.should match(/  dc:title "#{json_hash['title']}"\s*[;\.]$/)}
    end

    context "Subject Definitions" do
      specify {output.should match(/<#{ts['@id']}> a #{ts['@type'].join(', ')}\s*[;\.]$/)}
    end

    context "Test Case Definitions" do
      specify {output.should match(/<#{tc['@id']}> a #{tc['@type'].join(', ')}\s*[;\.]$/)}
    end

    context "Assertion" do
      specify {output.should match(/\[ a #{as['@type']}\s*[;\.]$/)}
    end

    context "parsing to RDF" do
      let(:graph) do
        @graph ||= begin
          RDF::Graph.new << RDF::Turtle::Reader.new(output, :base_uri => "http://example.com/report")
        end
      end

      it "has Report" do
        SPARQL.execute(REPORT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Subject" do
        SPARQL.execute(SUBJECT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Developer" do
        SPARQL.execute(DEVELOPER_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Test Case" do
        SPARQL.execute(TC_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Assertion" do
        SPARQL.execute(ASSERTION_QUERY, graph).should be_true
      end
    end
  end

  describe "#generate" do
    let(:output) {
      @output ||= begin
        subject.generate()
      end
    }

    context "parsing to RDF" do
      let(:graph) do
        @graph ||= begin
          RDF::Graph.new << RDF::RDFa::Reader.new(output, :base_uri => "http://example.com/report")
        end
      end

      it "has Report" do
        SPARQL.execute(REPORT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Subject" do
        SPARQL.execute(SUBJECT_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Developer" do
        SPARQL.execute(DEVELOPER_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Test Case" do
        SPARQL.execute(TC_QUERY, graph).should == RDF::Literal::TRUE
      end

      it "has Assertion" do
        SPARQL.execute(ASSERTION_QUERY, graph).should be_true
      end
    end
  end

  REPORT_QUERY = %(
    PREFIX dc: <http://purl.org/dc/terms/>
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    PREFIX earl: <http://www.w3.org/ns/earl#>
          
    ASK WHERE {
      ?uri a earl:Report;
        dc:title "Turtle Test Results";
        dc:bibliographicCitation "[[TURTLE]]";
        earl:generatedBy ?generatedBy;
        earl:assertions ?assertionFile;
        earl:testSubjects (<http://rubygems.org/gems/rdf-turtle>);
        earl:tests (
          <http://example/manifest.ttl#testeval00>
          ?test01
        ) .
    }
  )

  SUBJECT_QUERY = %(
    PREFIX doap: <http://usefulinc.com/ns/doap#>
    PREFIX earl: <http://www.w3.org/ns/earl#>
          
    ASK WHERE {
      <http://rubygems.org/gems/rdf-turtle> a earl:TestSubject, doap:Project;
        doap:name "RDF::Turtle";
        doap:description """RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite."""@en;
        doap:programming-language "Ruby";
        doap:developer <http://greggkellogg.net/foaf#me> .
    }
  )

  DEVELOPER_QUERY = %(
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          
    ASK WHERE {
      <http://greggkellogg.net/foaf#me> a foaf:Person;
        foaf:name "Gregg Kellogg";
        foaf:homepage <http://greggkellogg.net/> .
    }
  )

  TC_QUERY = %(
    PREFIX dc: <http://purl.org/dc/terms/>
    PREFIX earl: <http://www.w3.org/ns/earl#>
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
          
    ASK WHERE {
      <http://example/manifest.ttl#testeval00> a earl:TestCriterion, earl:TestCase;
        dc:title "subm-test-00";
        dc:description """Blank subject"""@en;
        mf:action <http://example/test-00.ttl>;
        mf:result <http://example/test-00.out>;
        earl:assertions (
          [ a earl:Assertion; earl:subject <http://rubygems.org/gems/rdf-turtle> ]
        ) .
    }
  )

  ASSERTION_QUERY = %(
    PREFIX earl: <http://www.w3.org/ns/earl#>
          
    ASK WHERE {
      [ a earl:Assertion;
        earl:assertedBy <http://greggkellogg.net/foaf#me>;
        earl:test <http://example/manifest.ttl#testeval00>;
        earl:subject <http://rubygems.org/gems/rdf-turtle>;
        earl:mode earl:automatic;
        earl:result [ a earl:TestResult; earl:outcome earl:passed] ] .
    }
  )
end