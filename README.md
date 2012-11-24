# earl-report
Ruby gem to consolidate multiple EARL report and generate a rollup conformance report.

## Description
Reads a test manifest in the
[standard RDF WG format](http://www.w3.org/2011/rdf-wg/wiki/Turtle_Test_Suite)
along with one or more individual EARL reports and generates a rollup report in
HTML+RDFa in [ReSpec][] format.

## Individual EARL reports
Results for individual implementations should be specified in Turtle form, but
may be specified in an any compatible RDF serialization (JSON-LD is presumed to
be a cached rollup report). The report is composed of `Assertion` declarations
in the following form:

    [ a earl:Assertion;
      earl:assertedBy <http://greggkellogg.net/foaf#me>;
      earl:subject <http://rubygems.org/gems/rdf-turtle>;
      earl:test <http://dvcs.w3.org/hg/rdf/raw-file/default/rdf-turtle/tests-ttl/manifest.ttl#turtle-syntax-file-01>;
      earl:result [
        a earl:TestResult;
        earl:outcome earl:passed;
        dc:date "2012-11-17T15:19:11-05:00"^^xsd:dateTime];
      earl:mode earl:automatic ] .

Additionally, `earl:subject` is expected to reference a [DOAP]() description
of the reported software, in the following form:

    <http://rubygems.org/gems/rdf-turtle> a doap:Project, earl:TestSubject, earl:Software ;
      doap:name          "RDF::Turtle" ;
      doap:developer     <http://greggkellogg.net/foaf#me> ;
      doap:homepage      <http://ruby-rdf.github.com/rdf-turtle> ;
      doap:description   "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite."@en ;
      doap:programming-language "Ruby" .

The [DOAP]() description may be included in the [EARL]() report. If not found,
the IRI identified by `earl:subject` will be dereferenced and is presumed to
provide a [DOAP]() specification of the test subject.

The `doap:developer` is expected to reference a [FOAF]() profile for the agent
(user or organization) responsible for the test subject. It is expected to be
of the following form:

    <http://greggkellogg.net/foaf#me> foaf:name "Gregg Kellogg" .

If not found, the IRI identified by `doap:developer`
will be dereferenced and is presumed to provide a [FOAF]() profile of the developer.

## Manifest query
The test manifest is used to generate `earl:TestCase` entries for each test
described in the test manifest. It will also summarize each test, including
any input and result files associated with the tests. The built-in query
is based on the [standard RDF WG format](). Alternative manifest formats
can be used by specifying a customized manifest query. The default query
is the following:

    PREFIX dc: <http://purl.org/dc/terms/>
    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT ?lh ?uri ?title ?description ?testAction ?testResult
    WHERE {
      ?uri mf:name ?title; mf:action ?testAction.
      OPTIONAL { ?uri rdfs:comment ?description. }
      OPTIONAL { ?uri mf:result ?testResult. }
      OPTIONAL { [ mf:entries ?lh] . ?lh rdf:first ?uri . }
    }

If any result has a non-null `?lh`, it is taken as the list head and used
to maintain the list order within `earl:tests`.

## Report generation template
The report template is in [ReSpec][] form using [Haml]() to generate individual report elements.

## Usage
The `earl-report` command may be used to directly create a report from zero or more input files, which are themselves [EARL][] report.

    gem install earl-report
    
    earl \
      --output FILE     # Location for generated report
      --tempate [FILE]  # Location of report template file; returns default if not specified
      --bibRef          # The default ReSpec-formatted bibliographic reference for the report
      --name            # The name of the software being reported upon
      --manifest FILE   # a test manifest used to define test descriptions
      --base URI        # Base URI to by applied when parsing test manifest
      --query FILE      # Alternative SPARQL query for extracting information from manifest
      report*           # one or more EARL report in most RDF formats

### Initialization File
`earl-report` can take defaults for options from an initialization file.
When run, `earl-report` attempts to open the file `.earl` in the current directory.
This file is in [YAML][] format with entries for each option.

## License

This software is licensed using [Unlicense](http://unlicense.org) and is freely available without encumbrance.

[DOAP]: https://github.com/edumbill/doap/wiki
[EARL]: http://www.w3.org/TR/EARL10-Schema/
[FOAF]: http://xmlns.com/foaf/spec/
[Haml]: http://haml.info/
