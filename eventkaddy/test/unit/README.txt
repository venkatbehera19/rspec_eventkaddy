None of these are really unit tests (they are not independant at all,
as they are tests for models which need to interact with other layers,
such as the database), but I quickly got impatient trying to figure
out the rails convention for adding new directories in the test 
directory that rake test will pick up. There are several fragile
methods on the internet that apparently have all broken or are for newer
versions of rails. So for now I'm just dumping all the tests in the
three standard directories. Ideally at some point we would come across
what exactly rails wants you to do to hook into their system.
