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
      before(:each) do
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me"))
      end

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
      before(:each) do
        RDF::Graph.should_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me"))
      end

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
      before(:each) do
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
        RDF::Graph.should_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me")).and_return(RDF::Graph.new << [RDF::Node.new, RDF.type, RDF::FOAF.Person])
      end

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
      "@type" =>  %w(earl:Software doap:Project),
      bibRef:     "[[TURTLE]]",
      name:       "Turtle Test Results"
    }.each do |prop, value|
      specify(prop) {json[prop].should == value}
    end

    it "testSubjects" do
      json.keys.should include(:testSubjects)
    end

    it "tests" do
      json.keys.should include(:testSubjects)
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
  
  describe "#earl_turtle" do
  end
end