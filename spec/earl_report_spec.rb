# coding: utf-8
$:.unshift "."
require 'spec_helper'

describe EarlReport do
  let!(:earl) {
    EarlReport.new(
      File.expand_path("../test-files/report-complete.ttl", __FILE__),
      :bibRef   =>       "[[TURTLE]]",
      :name     =>         "Turtle Test Results",
      :verbose  => false,
      :manifest => File.expand_path("../test-files/manifest.ttl", __FILE__))
  }
  subject {earl}

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
      lambda {EarlReport.new}.should raise_error("Test Manifests must be specified with :manifest option")
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
    let(:json) {earl.send(:json_hash)}
    subject {json}
    it {should be_a(Hash)}
    {
      "@id"    => "",
      "@type"  => ["earl:Software", "doap:Project"],
      'bibRef' => "[[TURTLE]]",
      'name'   => "Turtle Test Results"
    }.each do |prop, value|
      specify(prop) {subject[prop].should == value}
    end

    %w(assertions generatedBy testSubjects entries).each do |key|
      its(:keys) {should include(key)}
    end

    context "parsing to RDF" do
      let!(:graph) do
        RDF::Graph.new << JSON::LD::Reader.new(subject.to_json, :base_uri => "http://example.com/report")
      end

      it "saves output" do
        lambda {
          File.open(File.expand_path("../test-files/results.jsonld", __FILE__), "w") do |f|
            f.write(subject.to_json)
          end
        }.should_not raise_error
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
    let(:json) {earl.send(:json_test_subject_info)}
    subject {json}
    it {should be_a(Array)}
    its(:length) {should == 1}

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
    let(:json) {earl.send(:json_result_info)}
    subject {json}
    it {should be_a(Array)}
    its(:length) {should == 1}

    context 'entries' do
      let(:ts) {json.first}
      {
        "@id"   =>  "http://example/manifest.ttl",
        "@type" =>  %w(earl:Report mf:Manifest),
        title:      "Example Test Cases"
      }.each do |prop, value|
        specify(prop) {ts[prop.to_s].should == value}
      end

      it "should have two entries" do
        ts['entries'].length.should == 2
      end

      context "test case" do
        let(:tc) {ts['entries'].first}
        {
          "@id" =>      "http://example/manifest.ttl#testeval00",
          "@type" =>    %w(earl:TestCriterion earl:TestCase http://www.w3.org/ns/rdftest#TestTurtleEval),
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
  end

  describe "#test_subject_turtle" do
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
    let(:ttl) {earl.send(:test_subject_turtle, desc)}
    subject {ttl}

    its(:length) {should > 0}
    specify {should match(/<#{desc['@id']}> a/)}
    specify {should match(/ a #{desc['@type'].join(', ')}\s*[;\.]$/)}
    specify {should match(/ doap:name "#{desc['name']}"\s*[;\.]$/)}
    specify {should match(/ doap:description "#{desc['doapDesc']}"@en\s*[;\.]$/)}
    specify {should match(/ doap:programming-language "#{desc['language']}"\s*[;\.]$/)}
    specify {should match(/ doap:developer <#{desc['developer']['@id']}>/)}

    context "developer" do
      let(:dev) {desc['developer']}
      specify {should match(/<#{dev['@id']}> a/)}
      specify {should match(/ a #{dev['@type'].join(', ')}\s*[;\.]$/)}
      specify {should match(/ foaf:name "#{dev['foaf:name']}"\s*[;\.]$/)}
    end
  end

  describe "#tc_turtle" do
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
    let(:ttl) {earl.send(:tc_turtle, tc)}
    subject {ttl}
    its(:length) {should > 0}
    specify {should match(/<#{tc['@id']}> a/)}
    specify {should match(/ a #{tc['@type'].join(', ')}\s*[;\.]$/)}
    specify {should match(/ dc:title "#{tc['title']}"\s*[;\.]$/)}
    specify {should match(/ dc:description "#{tc['description']}"@en\s*[;\.]$/)}
    specify {should match(/ mf:action <#{tc['testAction']}>\s*[;\.]$/)}
    specify {should match(/ mf:result <#{tc['testResult']}>\s*[;\.]$/)}
    specify {should match(/ earl:assertions \(\s*\[ a earl:Assertion/m)}
  end

  describe "#as_turtle" do
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
    let(:ttl) {earl.send(:as_turtle, as)}
    subject {ttl}
    its(:length) {should > 0}
    specify {should match(/ a #{as['@type'].join(', ')}\s*[;\.]$/)}
    specify {should match(/ earl:assertedBy <#{as['assertedBy']}>\s*[;\.]$/)}
    specify {should match(/ earl:test <#{as['test']}>\s*[;\.]$/)}
    specify {should match(/ earl:subject <#{as['subject']}>\s*[;\.]$/)}
    specify {should match(/ earl:mode #{as['mode']}\s*[;\.]$/)}
    specify {should match(/ earl:result \[ a #{as['result']['@type']}; earl:outcome #{as['result']['outcome']} \]\]/)}
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

  describe "#earl_turtle" do
    let(:json_hash) {earl.send(:json_hash)}
    let(:output) {
      @output ||= begin
        sio = StringIO.new
        earl.send(:earl_turtle, {io: sio})
        sio.rewind
        sio.read
      end
    }
    subject {output}
    let(:ts) {json_hash['testSubjects'].first}
    let(:tm) {json_hash['entries'].first}
    let(:tc) {tm['entries'].first}
    let(:as) {tc['assertions'].first}

    context "prefixes" do
      %w(dc doap earl foaf mf owl rdf rdfs xsd).each do |pfx|
        specify {should match(/@prefix #{pfx}: </)}
      end
    end

    context "earl:Software" do
      specify {should match(/<> a earl:Software, doap:Project\s*[;\.]$/)}
      specify {should match(/  doap:name "#{json_hash['name']}"\s*[;\.]$/)}
    end

    context "Subject Definitions" do
      specify {should match(/<#{ts['@id']}> a #{ts['@type'].join(', ')}\s*[;\.]$/)}
    end

    context "Manifest Definitions" do
      specify {should match(/<#{tm['@id']}> a #{tm['@type'].join(', ')}\s*[;\.]$/)}
    end

    context "Test Case Definitions" do
      let(:types) {
        tc['@type'].map do |t|
          t.include?("://") ? "<#{t}>" : t
        end
      }
      specify {should match(/<#{tc['@id']}> a #{types.join(', ')}\s*[;\.]$/)}
    end

    context "Assertion" do
      specify {should match(/\[ a #{as['@type']}\s*[;\.]$/)}
    end

    context "parsing to RDF" do
      let(:graph) do
        @graph ||= begin
          RDF::Graph.new << RDF::Turtle::Reader.new(output, :base_uri => "http://example.com/report")
        end
      end

      it "saves output" do
        lambda {
          File.open(File.expand_path("../test-files/results.ttl", __FILE__), "w") do |f|
            f.write(output)
          end
        }.should_not raise_error
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

      it "saves output" do
        lambda {
          File.open(File.expand_path("../test-files/results.html", __FILE__), "w") do |f|
            f.write(output)
          end
        }.should_not raise_error
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
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>

    ASK WHERE {
      ?uri a earl:Software, doap:Project;
        doap:name "Turtle Test Results";
        dc:bibliographicCitation "[[TURTLE]]";
        earl:generatedBy ?generatedBy;
        earl:assertions ?assertionFile;
        earl:testSubjects (<http://rubygems.org/gems/rdf-turtle>);
        mf:entries (<http://example/manifest.ttl>) .

      <http://example/manifest.ttl> a earl:Report, mf:Manifest;
        dc:title "Example Test Cases";
        mf:entries (
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