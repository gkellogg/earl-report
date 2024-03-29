# earl-report
Ruby gem to consolidate multiple [EARL][] report and generate a rollup conformance report.

[![Gem Version](https://badge.fury.io/rb/earl-report.png)](http://badge.fury.io/rb/earl-report)
[![Build Status](https://github.com/gkellogg/earl-report/workflows/CI/badge.svg?branch=develop)](https://github.com/gkellogg/earl-report/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/gkellogg/earl-report/badge.svg?branch=develop)](https://coveralls.io/r/gkellogg/earl-report?branch=develop)

## Description
Reads a test manifest in the
[standard RDF WG format](http://www.w3.org/2011/rdf-wg/wiki/Turtle_Test_Suite)
along with one or more individual <abbr title="Evaluation and Report Language (EARL) 1.0 Schema">[EARL][]</abbr> reports and generates a rollup report in HTML in [ReSpec][] format.

[EARL]() reports use the [Evaluation and Report Language (EARL) 1.0 Schema][EARL] to describe test results in RDF to relate the results for a given _subject_ to a _test_ defined in a _test manifest_.

## Individual EARL reports
Results for individual implementations should be specified in Turtle form, but
may be specified in an any compatible RDF serialization. The report is composed of `Assertion` declarations
in the following form:

    [ a earl:Assertion;
      earl:assertedBy <https://greggkellogg.net/foaf#me>;
      earl:subject <https://rubygems.org/gems/rdf-turtle>;
      earl:test <http://dvcs.w3.org/hg/rdf/raw-file/default/rdf-turtle/tests-ttl/manifest.ttl#turtle-syntax-file-01>;
      earl:result [
        a earl:TestResult;
        earl:outcome earl:passed;
        dc:date "2012-11-17T15:19:11-05:00"^^xsd:dateTime];
      earl:mode earl:automatic ] .

Additionally, `earl:subject` is expected to reference a [DOAP][] description
of the reported software, in the following form:

    <https://rubygems.org/gems/rdf-turtle> a doap:Project, earl:TestSubject, earl:Software ;
      doap:name          "RDF::Turtle" ;
      doap:developer     <https://greggkellogg.net/foaf#me> ;
      doap:homepage      <https://ruby-rdf.github.io/rdf-turtle> ;
      doap:description   "RDF::Turtle is an Turtle reader/writer for the RDF.rb library suite."@en ;
      doap:release [
                         doap:name "RDF::Turtle 3.1.0" ;
                         doap:created "2015-09-27"^^xsd:date ;
                         doap:revision "3.1.0"
      ] ;
      doap:programming-language "Ruby" .

The [DOAP][] description may be included in the [EARL][] report. If not found,
the IRI identified by `earl:subject` will be dereferenced and is presumed to
provide a [DOAP][] specification of the test subject.

The `doap:developer` is expected to reference a [FOAF][] profile for the agent
(user or organization) responsible for the test subject. It is expected to be
of the following form:

    <https://greggkellogg.net/foaf#me> foaf:name "Gregg Kellogg" .

If not found, the IRI identified by `doap:developer`
will be dereferenced and is presumed to provide a [FOAF][] profile of the developer.

Assertions are added to each test entry based on that test being referenced from the assertion.

## Manifest query
The test manifest is used to find test entries and a manifest. The built-in
query is based on the [standard RDF WG format][]. Alternative manifest formats
can be used by specifying a customized manifest query, but may require a custom
[Haml][] template for report generation. The default query is the following:

    PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

    SELECT ?uri ?testAction ?manUri
    WHERE {
      ?uri mf:action ?testAction .
      OPTIONAL {
        ?manUri a mf:Manifest; mf:entries ?lh .
        ?lh rdf:first ?uri .
      }
    }

## Report generation template
The report template is in [ReSpec][] form using [Haml][] to generate individual report elements.

## Changes from previous versions
### Version 0.7
Version 0.7 creates incompatibilities with previous result formats. Previously, terms were "added" to the EARL vocabulary to help with coordination. This version pulls that back, but does depend on an added `earl:Report` class which acts as an appropriate container for for collections of  `earl:Assertion`.

Within an `earl:TestCase`, the former `earl:assertions` property is replaced with a reverse property on `earl:test` so that, in the JSON-LD representation, an `earl:TestCase` will contain a property representing the related assertions.

Also, `earl:assertions` had been miss-appropriated to reference the sources of the individual test results provided for each test subject. A new property as appropriated from the Test Manifest vocabulary: `mf:report`. The alias `assertions` continues to be used within the JSON-LD representation, although it now maps to `mf:report` at the top level, and as mentioned, is a reverse property of `earl:test` within an `earl:TestCase`.

These changes may require updates to customized Haml templates.

### Version 0.3
Version 0.3 and prior re-constructed the test manifest used to create the body of the report, which caused information not described within the query to be lost. Starting with 0.4, all manifests and assertions are read into a single graph, and each test references a list of assertions against it using a list referenced by `mf:assertions`. Additionally, all included manifests are included in a top-level entity referenced via `mf:entries`. For example:

    <> a earl:Software, doap:Project;
       mf:entries (<http://example/manifest.ttl>);
       mf:assertions (<spec/test-files/report-complete.ttl>)  .

    <http://example/manifest.ttl> a mf:Manifest, earl:Report;
       mf:name "Example Test Cases";
       rdfs:comment "Description for Example Test Cases";
       mf:entries (<http://example/manifest.ttl#testeval00>) .

    <http://example/manifest.ttl#testeval00> a earl:TestCriterion, earl:TestCase;
       mf:name "subm-test-00";
       rdfs:comment "Blank subject";
       mf:action <http://example/test-00.ttl>;
       mf:result <http://example/test-00.out>;
       mf:assertions ([
           a earl:Assertion;
           earl:assertedBy <https://greggkellogg.net/foaf#me>;
           earl:mode earl:automatic;
           earl:result [
             a earl:TestResult;
             dc:date "2012-11-06T19:23:29-08:00"^^xsd:dateTime;
             earl:outcome earl:passed
           ];
           earl:subject <https://rubygems.org/gems/rdf-turtle>;
           earl:test <http://example/manifest.ttl#testeval00>
         ]) .

## Usage
The `earl-report` command may be used to directly create a report from zero or more input files, which are themselves [EARL][] report.

    gem install earl-report
    
    earl-report \
      --base            # Base URI to use when loading test manifest
      --bibRef          # ReSpec BibRef of specification being reported upon
      --format          # Format of output, one of 'ttl', 'json', or 'html'
      --json            # Input is a JSON-LD formatted result
      --manifest        # Test manifest
      --name            # Name of specification
      --output          # Output report to file
      --query           # Query, or file containing query for extracting information from Test manifest
      --rc              # Write options to run-control file
      --template        # Specify or return default report template
      report*           # one or more EARL report in most RDF formats

Generally, creating a `json` format first is more efficient. Subsequent invocations can then use the `--json` and use the generated JSON-LD file instead of re-parsing each report.

### Initialization File
`earl-report` can take defaults for options from an initialization file.
When run, `earl-report` attempts to open the file `.earl` in the current directory. This file is in [YAML][] format with entries for each option. Use the `--rc` option to automatically generate it.

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## License

This software is licensed using [Unlicense](http://unlicense.org) and is freely available without encumbrance.

[DOAP]:   https://github.com/edumbill/doap/wiki
[EARL]:   http://www.w3.org/TR/EARL10-Schema/
[FOAF]:   http://xmlns.com/foaf/spec/
[Haml]:   http://haml.info/
[YAML]:   http://www.yaml.org/
[ReSpec]: http://dev.w3.org/2009/dap/ReSpec.js/documentation.html
