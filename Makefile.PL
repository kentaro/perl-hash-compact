use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name     'Hash-Compact';
all_from 'lib/Hash/Compact.pm';
license  'MIT';

readme_markdown_from 'lib/Hash/Compact.pm';

requires 'Scalar::Util';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
