Mongoid Documentation
=================================

This subdirectory contains the high-level driver documentation, including
tutorials and the reference.

To build the documentation locally for review, install `sphinx` and
`sphinx-book-theme`, then execute `make html` in this directory:

    pip install 'sphinx<4.3' sphinx-book-theme
    make html

Note: sphinx 4.3 is currently breaking when trying to render Mongoid
documentation.
