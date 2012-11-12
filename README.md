# earl-report
============

Ruby gem to consolidate multiple EARL report and generate a rollup conformance report

## Description

## Usage

The `earl` command may be used to directly create a report from zero or more input files, which are themselves [EARL][] report.

    gem install earl-report
    
    earl \
      --haml FILE   # HAML/Markdown template
      --output FILE # Location for generated report
      report*       # zero or more EARL report in most RDF formats

## Format of EARL report inputs

## Report generation template