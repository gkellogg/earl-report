# coding: utf-8
$:.unshift "."
require 'spec_helper'

describe EarlReports do
  describe ".new" do
    context "complete report" do
      before(:each) do
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://rubygems.org/gems/rdf-turtle"))
        RDF::Graph.should_not_receive(:load).with(RDF::URI("http://greggkellogg.net/foaf#me"))
      end

      subject {
        EarlReports.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-complete.ttl", __FILE__))
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
        EarlReports.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-no-doap.ttl", __FILE__))
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
        EarlReports.new(
          File.expand_path("../test-files/manifest.ttl", __FILE__),
          File.expand_path("../test-files/report-no-foaf.ttl", __FILE__))
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
  end
  
  describe "#json_subject_info" do
  end
  
  describe "#json_result_info" do
  end
  
  describe "#earl_turtle" do
  end
end