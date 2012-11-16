# coding: utf-8
$:.unshift "."
require 'spec_helper'

describe EarlReport do
  subject {
    EarlReport.new(
      File.expand_path("../test-files/manifest.ttl", __FILE__),
      File.expand_path("../test-files/report-complete.ttl", __FILE__),
      :verbose => false)
  }

  describe ".new" do
    context "complete report" do
      #before(:each) do
      #  RDF::Graph.should_not_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      #  RDF::Graph.should_not_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me"))
      #end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-complete.ttl", __FILE__),
          :verbose => false)
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
      #before(:each) do
      #  RDF::Graph.should_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      #  RDF::Graph.should_not_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me"))
      #end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-no-doap.ttl", __FILE__),
          :verbose => false)
      }
      it "loads manifest" do
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl"))
        subject.graph.subjects.to_a.should include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        subject.graph.predicates.to_a.should include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "does not load doap" do
        subject.graph.subjects.to_a.should_not include(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        subject.graph.objects.to_a.should include(RDF::FOAF.Person)
      end
    end

    context "no foaf report" do
      #before(:each) do
      #  RDF::Graph.should_not_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
      #  RDF::Graph.should_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me")).and_return(RDF::Graph.new << [RDF::Node.new, RDF.type, RDF::FOAF.Person])
      #end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-no-foaf.ttl", __FILE__),
          :verbose => false)
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
  
  describe ".generate" do
  end
  
  describe "#json_hash" do
    let(:json) {
      subject.send(:json_hash, {
        bibRef:       "[[TURTLE]]",
        name:         "Turtle Test Results"
      })
    }
    specify {json.should be_a(Hash)}
    {
      "@id"    => "",
      "@type"  => %w(earl:Software doap:Project),
      'bibRef' => "[[TURTLE]]",
      'name'   => "Turtle Test Results"
    }.each do |prop, value|
      specify(prop) {json[prop].should == value}
    end

    it "testSubjects" do
      json.keys.should include('testSubjects')
    end

    it "tests" do
      json.keys.should include('tests')
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
        doap_desc:  "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite.",
        homepage:   "http://ruby-rdf.github.com/rdf-turtle",
        language:   "Ruby",
        name:       "RDF::Turtle",
      }.each do |prop, value|
        specify(prop) {ts[prop.to_s].should == value}
      end
      
      context "developer" do
        let(:dev) {ts['developer']}
        specify {dev.should be_a(Hash)}
        {
          "@id"       => "http://greggkellogg.net/foaf#me",
          "@type"     => %(foaf:Person),
          "foaf:name" => "Gregg Kellogg",
        }.each do |prop, value|
          specify(prop) {dev[prop.to_s].should == value}
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

      context "assertion" do
        let(:as) {tc['http://rubygems.org/gems/rdf-turtle']}
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
        'doap_desc' => "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite.",
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
        ttl.should match(/ a #{desc['@type'].join(', ')};$/)
      end
      it "has name" do
        ttl.should match(/ doap:name "#{desc['name']}";$/)
      end
      it "has description" do
        ttl.should match(/ doap:description """#{desc['doap_desc']}""";$/)
      end
      it "has doap:programming-language" do
        ttl.should match(/ doap:programming-language "#{desc['language']}";$/)
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
          ttl.should match(/ a #{dev['@type'].join(', ')};$/)
        end
        it "has name" do
          ttl.should match(/ foaf:name "#{dev['foaf:name']}" .$/)
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
      }}
      let(:ttl) {subject.send(:tc_turtle, tc)}
      specify {ttl.length.should > 0}
      it "has subject subject" do
        ttl.should match(/<#{tc['@id']}> a/)
      end
      it "has types" do
        ttl.should match(/ a #{tc['@type'].join(', ')};$/)
      end
      it "has dc:title" do
        ttl.should match(/ dc:title "#{tc['title']}";$/)
      end
      it "has dc:description" do
        ttl.should match(/ dc:description """#{tc['description']}""";$/)
      end
      it "has mf:action" do
        ttl.should match(/ mf:action <#{tc['testAction']}>;$/)
      end
      it "has mf:result" do
        ttl.should match(/ mf:result <#{tc['testResult']}>;$/)
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
        ttl.should match(/ a #{as['@type'].join(', ')};$/)
      end
      it "has earl:assertedBy" do
        ttl.should match(/ earl:assertedBy <#{as['assertedBy']}>;$/)
      end
      it "has earl:test" do
        ttl.should match(/ earl:test <#{as['test']}>;$/)
      end
      it "has earl:subject" do
        ttl.should match(/ earl:subject <#{as['subject']}>;$/)
      end
      it "has earl:mode" do
        ttl.should match(/ earl:mode #{as['mode']};$/)
      end
      it "has earl:result" do
        ttl.should match(/ earl:result \[ a #{as['result']['@type']}; earl:outcome #{as['result']['outcome']}\]/)
      end
    end
  end

  describe "#earl_turtle" do
    let(:results) {
      @results ||= JSON.parse(File.read(File.expand_path("../test-files/results.jsonld", __FILE__)))
    }
    let(:output) {
      @output ||= begin
        sio = StringIO.new
        subject.send(:earl_turtle, {json_hash: results, io: sio})
        sio.rewind
        sio.read
      end
    }
    let(:ts) {results['testSubjects'].first}
    let(:tc) {results['tests'].first}
    let(:as) {tc[ts['@id']]}

    context "prefixes" do
      %w(dc doap earl foaf mf owl rdf rdfs xsd).each do |pfx|
        it "should have prefix #{pfx}" do
          output.should match(/@prefix #{pfx}: </)
        end
      end
    end

    context "earl:Software" do
      specify {output.should match(/<> a earl:Software, doap:Project;/)}
      specify {output.should match(/  doap:name "#{results['name']}"\./)}
    end

    context "Subject Definitions" do
      specify {output.should match(/<#{ts['@id']}> a #{ts['@type'].join(', ')};/)}
    end

    context "Test Case Definitions" do
      specify {output.should match(/<#{tc['@id']}> a #{tc['@type'].join(', ')};/)}
    end

    context "Assertion" do
      specify {output.should match(/\[ a #{as['@type']};/)}
    end
  end
end