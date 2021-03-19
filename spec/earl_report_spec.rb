# coding: utf-8
$:.unshift "."
require 'spec_helper'

describe EarlReport do
  let!(:earl) {
    EarlReport.new(
      File.expand_path("../test-files/report-complete.ttl", __FILE__),
      bibRef:   "[[TURTLE]]",
      name:     "Turtle Test Results",
      verbose:  false,
      manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
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
    let(:reportNoTest) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/report-no-test.ttl", __FILE__))
    }
    let(:doap) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/doap.ttl", __FILE__))
    }
    let(:foaf) {
      RDF::Graph.new << RDF::Turtle::Reader.new(File.open File.expand_path("../test-files/foaf.ttl", __FILE__))
    }

    it "requires a :manifest option" do
      expect {EarlReport.new}.to raise_error("Test Manifests must be specified with :manifest option")
    end

    context "with base" do
      it "loads manifest relative to base" do
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {unique_bnodes: true, base_uri: "http://example.com/base/"})
          .and_return(manifest)
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/report-complete.ttl", __FILE__))
          .and_return(reportComplete)
        EarlReport.new(
          File.expand_path("../test-files/report-complete.ttl", __FILE__),
          verbose: false,
          base: "http://example.com/base/",
          manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
      end
    end

    context "complete report" do
      before(:each) do
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {unique_bnodes: true, })
          .and_return(manifest)
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/report-complete.ttl", __FILE__))
          .and_return(reportComplete)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-complete.ttl", __FILE__),
          verbose: false,
          manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl"))
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        expect(subject.graph.predicates.to_a).to include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("https://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        expect(subject.graph.objects.to_a).to include(RDF::Vocab::FOAF.Person)
      end
    end

    context "no doap report" do
      before(:each) do
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {unique_bnodes: true, })
          .and_return(manifest)
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/report-no-doap.ttl", __FILE__))
          .and_return(reportNoDoap)
        expect(RDF::Graph).to receive(:load)
          .with("https://rubygems.org/gems/rdf-turtle")
          .and_return(doap)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-no-doap.ttl", __FILE__),
          verbose: false,
          manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl"))
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        expect(subject.graph.predicates.to_a).to include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("https://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        expect(subject.graph.objects.to_a).to include(RDF::Vocab::FOAF.Person)
      end
    end

    context "no foaf report" do
      before(:each) do
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {unique_bnodes: true, })
          .and_return(manifest)
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/report-no-foaf.ttl", __FILE__))
          .and_return(reportNoFoaf)
        expect(RDF::Graph).to receive(:load)
          .with("https://greggkellogg.net/foaf#me")
          .and_return(foaf)
      end

      subject {
        EarlReport.new(
          File.expand_path("../test-files/report-no-foaf.ttl", __FILE__),
          verbose: false,
          manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
      }
      it "loads manifest" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl"))
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        expect(subject.graph.predicates.to_a).to include(RDF::URI("http://www.w3.org/ns/earl#assertedBy"))
      end

      it "loads doap" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("https://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        expect(subject.graph.objects.to_a).to include(RDF::Vocab::FOAF.Person)
      end
    end

    context "asserts a test not in manifest" do
      before(:each) do
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/manifest.ttl", __FILE__), {unique_bnodes: true, })
          .and_return(manifest)
        expect(RDF::Graph).to receive(:load)
          .with(File.expand_path("../test-files/report-no-test.ttl", __FILE__))
          .and_return(reportNoTest)
      end

      subject {
        expect do
          @no_test_earl = EarlReport.new(
            File.expand_path("../test-files/report-no-test.ttl", __FILE__),
            verbose: false,
            manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
        end.to output.to_stderr
        @no_test_earl
      }
      it "loads manifest" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl"))
        expect(subject.graph.subjects.to_a).to include(RDF::URI("http://example/manifest.ttl#testeval00"))
      end

      it "loads report" do
        expect(subject.graph.predicates.to_a).to include(RDF::URI("http://www.w3.org/ns/earl#generatedBy"))
      end

      it "loads doap" do
        expect(subject.graph.subjects.to_a).to include(RDF::URI("https://rubygems.org/gems/rdf-turtle"))
      end

      it "loads foaf" do
        expect(subject.graph.objects.to_a).to include(RDF::Vocab::FOAF.Person)
      end

      it "raises an error if the strict option is used" do
        expect do
          expect do
            EarlReport.new(
              File.expand_path("../test-files/report-no-test.ttl", __FILE__),
              verbose: false,
              strict: true,
              manifest: File.expand_path("../test-files/manifest.ttl", __FILE__))
          end.to raise_error(Exception)
        end.to output.to_stderr
      end
    end
  end
  
  describe "#json_hash" do
    let(:json) {earl.send(:json_hash)}
    subject {json}
    it {is_expected.to be_a(Hash)}
    {
      "@id"    => "",
      "@type"  => ["Software", "doap:Project"],
      'bibRef' => "[[TURTLE]]",
      'name'   => "Turtle Test Results"
    }.each do |prop, value|
      if value.is_a?(Array)
        specify(prop) {expect(subject[prop]).to include(*value)}
      else
        specify(prop) {expect(subject[prop]).to eq value}
      end
    end

    %w(assertions generatedBy testSubjects entries).each do |key|
      its(:keys) {is_expected.to include(key)}
    end

    context "parsing to RDF" do
      let!(:graph) do
        RDF::Graph.new << JSON::LD::Reader.new(subject.to_json, :base_uri => "http://example.com/report")
      end

      it "saves output as JSON-LD" do
        expect {
          File.open(File.expand_path("../test-files/results.jsonld", __FILE__), "w") do |f|
            f.write(subject.to_json(JSON::LD::JSON_STATE))
          end
        }.not_to raise_error
      end

      it "has Report" do
        expect(SPARQL.execute(REPORT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Subject" do
        expect(SPARQL.execute(SUBJECT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Developer" do
        expect(SPARQL.execute(DEVELOPER_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Test Case" do
        expect(SPARQL.execute(TC_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Assertion" do
        expect(SPARQL.execute(ASSERTION_QUERY, graph)).to be_truthy
      end
    end

    it "raises error if manifest query returns no solutions", pending: "needs new test" do
      fail
    end
  end

  describe "#earl_turtle" do
    let(:json_hash) {earl.send(:json_hash)}
    let(:output) {
      @output ||= begin
        sio = StringIO.new
        earl.send(:earl_turtle, io: sio)
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
      %w(dc doap earl foaf mf rdf rdfs xsd).each do |pfx|
        specify {is_expected.to match(/@prefix #{pfx}:\s+</)}
      end
    end

    context "earl:Software" do
      specify {is_expected.to match(%r{<> a [^;]*earl:Software[^;]*;$}m)}
      specify {is_expected.to match(%r{<> a [^;]*doap:Project[^;]*;$}m)}
      specify {is_expected.to match(/  doap:name "#{json_hash['name']}"\s*[;\.]$/)}
    end

    context "Subject Definitions" do
      specify {is_expected.to match(%r{<#{ts['@id']}> a [^;]*doap:Project[^;]*;$}m)}
      specify {is_expected.to match(%r{<#{ts['@id']}> a [^;]*earl:TestSubject[^;]*;$}m)}
      specify {is_expected.to match(%r{<#{ts['@id']}> a [^;]*earl:Software[^;]*;$}m)}
    end

    context "Manifest Definitions" do
      specify {
        json_hash
        is_expected.to match(%r{<#{tm['@id']}> a [^;]*mf:Manifest[^;]*;$}m)}
      specify {is_expected.to match(%r{<#{tm['@id']}> a [^;]*earl:Report[^;]*;$}m)}
    end

    context "Assertion" do
      specify {is_expected.to match(/\sa earl:Assertion\s*;$/)}
    end

    context "parsing to RDF" do
      let(:graph) do
        @graph ||= begin
          RDF::Graph.new << RDF::Turtle::Reader.new(output, :base_uri => "http://example.com/report")
        end
      end

      it "saves output" do
        expect {
          File.open(File.expand_path("../test-files/results.ttl", __FILE__), "w") do |f|
            f.write(output)
          end
        }.not_to raise_error
      end

      it "has Report" do
        expect(SPARQL.execute(REPORT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Subject" do
        expect(SPARQL.execute(SUBJECT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Developer" do
        expect(SPARQL.execute(DEVELOPER_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Test Case" do
        expect(SPARQL.execute(TC_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Assertion" do
        expect(SPARQL.execute(ASSERTION_QUERY, graph)).to be_truthy
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

      it "saves output as HTML" do
        expect {
          File.open(File.expand_path("../test-files/results.html", __FILE__), "w") do |f|
            f.write(output)
          end
        }.not_to raise_error
      end

      it "saves output as Turtle" do
        output = subject.generate(format: :turtle)
        expect {
          File.open(File.expand_path("../test-files/results.ttl", __FILE__), "w") do |f|
            f.write(output)
          end
        }.not_to raise_error
      end

      context "output as JSON-LD" do
        let(:output) {subject.generate(format: :jsonld)}
        it "saves output" do
          expect {
            File.open(File.expand_path("../test-files/results.jsonld", __FILE__), "w") do |f|
              f.write(output)
            end
          }.not_to raise_error
        end

        it "reads a previously generated JSON-LD file" do
          expect {EarlReport.new(File.expand_path("../test-files/results.jsonld", __FILE__), json: true)}.not_to raise_error
        end
      end

      it "has Report" do
        expect(SPARQL.execute(REPORT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Subject" do
        expect(SPARQL.execute(SUBJECT_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Developer" do
        expect(SPARQL.execute(DEVELOPER_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Test Case" do
        expect(SPARQL.execute(TC_QUERY, graph)).to eq RDF::Literal::TRUE
      end

      it "has Assertion" do
        expect(SPARQL.execute(ASSERTION_QUERY, graph)).to be_truthy
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
        earl:testSubjects <https://rubygems.org/gems/rdf-turtle>;
        mf:entries (<http://example/manifest.ttl>) .

      <http://example/manifest.ttl> a earl:Report, mf:Manifest;
        mf:name "Example Test Cases";
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
      <https://rubygems.org/gems/rdf-turtle> a earl:TestSubject, doap:Project;
        doap:name "RDF::Turtle";
        doap:description """RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite."""@en;
        doap:programming-language "Ruby";
        doap:developer <https://greggkellogg.net/foaf#me> .
    }
  )

  DEVELOPER_QUERY = %(
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          
    ASK WHERE {
      <https://greggkellogg.net/foaf#me> a foaf:Person;
        foaf:name "Gregg Kellogg";
        foaf:homepage <https://greggkellogg.net/> .
    }
  )

  TC_QUERY = %(
    PREFIX dc: <http://purl.org/dc/terms/>
    PREFIX earl: <http://www.w3.org/ns/earl#>
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
          
    ASK WHERE {
      <http://example/manifest.ttl#testeval00> a earl:TestCriterion, earl:TestCase;
        mf:name "subm-test-00";
        mf:action <http://example/test-00.ttl>;
        mf:result <http://example/test-00.out>;
        earl:assertions [ a earl:Assertion; earl:subject <https://rubygems.org/gems/rdf-turtle> ] .
    }
  )

  ASSERTION_QUERY = %(
    PREFIX earl: <http://www.w3.org/ns/earl#>
          
    ASK WHERE {
      [ a earl:Assertion;
        earl:assertedBy <https://greggkellogg.net/foaf#me>;
        earl:test <http://example/manifest.ttl#testeval00>;
        earl:subject <https://rubygems.org/gems/rdf-turtle>;
        earl:mode earl:automatic;
        earl:result [ a earl:TestResult; earl:outcome earl:passed] ] .
    }
  )
end