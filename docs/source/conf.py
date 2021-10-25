# -*- coding: utf-8 -*-
#
# Configuration file for the Sphinx documentation builder.
#
# This file does only contain a selection of the most common options. For a
# full list see the documentation:
# http://www.sphinx-doc.org/en/stable/config

# -- Path setup --------------------------------------------------------------

import os
import platform
import subprocess
import sys
import urllib

import supy

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
sys.path.insert(0, os.path.abspath("."))

print(r"this build is made by:", "\n", sys.version)
print(r"this build is for:", "\n")
supy.show_version()


def subprocess_cmd(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    proc_stdout = process.communicate()[0].strip()
    print(proc_stdout.decode())


# run script to generate rst files for df_{group}
subprocess_cmd('cd proc_var_info; python3 gen_rst.py')


# -- Project information -----------------------------------------------------

project = "SuPy"
doc_name = "SuPy Documentation"
author = "Dr Ting Sun, Dr Hamidreza Omidvar and Prof Sue Grimmond"
year = "2018–2021"
copyright = ", ".join([year, author])


# The short X.Y version
version = supy.__version__.strip()
# The full version, including alpha/beta/rc tags
release = supy.__version__.strip()


# -- General configuration ---------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "nbsphinx",
    "sphinx.ext.mathjax",
    "sphinx.ext.ifconfig",
    "sphinx.ext.viewcode",
    # 'rinoh.frontend.sphinx',
    # 'sphinxfortran.fortran_autodoc',
    # 'sphinxfortran.fortran_domain',
    "sphinx.ext.autosectionlabel",
    "sphinx.ext.githubpages",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.intersphinx",
    "sphinx.ext.extlinks",
    "sphinx.ext.mathjax",
    "sphinx.ext.napoleon",
    "sphinx.ext.ifconfig",
    "sphinx.ext.viewcode",
    "sphinx_comments",
    "IPython.sphinxext.ipython_directive",
    "IPython.sphinxext.ipython_console_highlighting",
    "sphinx_click.ext",
    # 'sphinx_gallery.gen_gallery',
]

extlinks = {
    "issue": ("https://github.com/UMEP-dev/SuPy/issues/%s", "GH"),
    "pull": ("https://github.com/UMEP-dev/SuPy/pull/%s", "PR"),
    "doi": ("http://dx.doi.org/%s", "DOI: "),
}

# sphinx comments
# https://sphinx-comments.readthedocs.io/
comments_config = {
    "hypothesis": True,
    "utterances": {
        "repo": "UMEP-dev/SuPy",
        "issue-term": "title",
        #   "optional": "config",
    },
}

autosummary_generate = True

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = ".rst"

# The master toctree document.
master_doc = "index"
master_doc_latex = "index_latex"

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path .

exclude_patterns = ["_build", "**.ipynb_checkpoints"]
# tags.add('html')
# if tags.has('html'):
#     exclude_patterns = ['references.rst']

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = "sphinx"

# default interpretation of `role` markups
default_role = "any"

# some text replacement defintions
rst_prolog = r"""
.. |km^-1| replace:: km\ :sup:`-1`
.. |mm^-1| replace:: mm\ :sup:`-1`
.. |m^-1| replace:: m\ :sup:`-1`
.. |m^-2| replace:: m\ :sup:`-2`
.. |m^-3| replace:: m\ :sup:`-3`
.. |m^3| replace:: m\ :sup:`3`
.. |s^-1| replace:: s\ :sup:`-1`
.. |kg^-1| replace:: kg\ :sup:`-1`
.. |K^-1| replace:: K\ :sup:`-1`
.. |W^-1| replace:: W\ :sup:`-1`
.. |h^-1| replace:: h\ :sup:`-1`
.. |ha^-1| replace:: ha\ :sup:`-1`
.. |QF| replace:: Q\ :sub:`F`
.. |Qstar| replace:: Q\ :sup:`*`
.. |d^-1| replace:: d\ :sup:`-1`
.. |d^-2| replace:: d\ :sup:`-2`
.. |)^-1| replace:: )\ :sup:`-1`
.. |Recmd| replace:: **Recommended in this version.**
.. |NotRecmd| replace:: **Not recommended in this version.**
.. |NotAvail| replace:: **Not available in this version.**
.. |NotUsed| replace:: **Not used in this version.**
"""
# -- Options for HTML output -------------------------------------------------
# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"
html_theme_path = ["_themes"]

# some text replacement defintions
rst_prolog = """
.. |km^-1| replace:: km\ :sup:`-1`
.. |mm^-1| replace:: mm\ :sup:`-1`
.. |m^-1| replace:: m\ :sup:`-1`
.. |m^-2| replace:: m\ :sup:`-2`
.. |m^-3| replace:: m\ :sup:`-3`
.. |m^3| replace:: m\ :sup:`3`
.. |s^-1| replace:: s\ :sup:`-1`
.. |kg^-1| replace:: kg\ :sup:`-1`
.. |K^-1| replace:: K\ :sup:`-1`
.. |W^-1| replace:: W\ :sup:`-1`
.. |h^-1| replace:: h\ :sup:`-1`
.. |ha^-1| replace:: ha\ :sup:`-1`
.. |QF| replace:: Q\ :sub:`F`
.. |Qstar| replace:: Q\ :sup:`*`
.. |d^-1| replace:: d\ :sup:`-1`
.. |d^-2| replace:: d\ :sup:`-2`
.. |)^-1| replace:: )\ :sup:`-1`
.. |Recmd| replace:: **Recommended in this version.**
.. |NotRecmd| replace:: **Not recommended in this version.**
.. |NotAvail| replace:: **Not available in this version.**
.. |NotUsed| replace:: **Not used in this version.**


.. only:: html

    .. tip::

      1. Need help? Please let us know in the `UMEP Community`_.
      2. Find an issue within this page? Please report it in the `GitHub issues`_.
      3. A good understanding of `SUEWS <https://suews.readthedocs.org>`_ is a prerequisite to the proper use of SuPy.


.. _UMEP Community : https://github.com/UMEP-dev/UMEP/discussions/

"""

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}
# This is processed by Jinja2 and inserted before each notebook
nbsphinx_prolog = r"""
{% set docname = 'docs/source/' + env.doc2path(env.docname, base=False) %}

.. raw:: html

    <div class="admonition note">
      This page was generated from
      <a class="reference external" href="https://github.com/UMEP-dev/SuPy/blob/{{ env.config.release|e }}/{{ docname|e }}">{{ docname|e }}</a>.
      Interactive online version:
      <span style="white-space: nowrap;"><a href="https://mybinder.org/v2/gh/UMEP-dev/SuPy/{{ env.config.release|e }}?filepath={{ docname|e }}"><img alt="Binder badge" src="https://mybinder.org/badge_logo.svg" style="vertical-align:text-bottom"></a>.</span>
      <script>
        if (document.location.host) {
          $(document.currentScript).replaceWith(
            '<a class="reference external" ' +
            'href="https://nbviewer.jupyter.org/url' +
            (window.location.protocol == 'https:' ? 's/' : '/') +
            window.location.host +
            window.location.pathname.slice(0, -4) +
            'ipynb">View in <em>nbviewer</em></a>.'
          );
        }
      </script>
    </div>

.. raw:: latex

    \nbsphinxstartnotebook{\scriptsize\noindent\strut
    \textcolor{gray}{The following section was generated from
    \sphinxcode{\sphinxupquote{\strut {{ docname | escape_latex }}}} \dotfill}}
"""

# This is processed by Jinja2 and inserted after each notebook
nbsphinx_epilog = r"""
{% set docname = 'docs/source/' + env.doc2path(env.docname, base=None) %}
.. raw:: latex

    \nbsphinxstopnotebook{\scriptsize\noindent\strut
    \textcolor{gray}{\dotfill\ \sphinxcode{\sphinxupquote{\strut
    {{ docname | escape_latex }}}} ends here.}}
"""

# three possible settings, "always", "auto" and "never".
# By default (= "auto"), notebooks with no outputs are executed and notebooks with at least one output are not.
# As always, per-notebook settings take precedence over the settings in conf.py.
if platform.system() == "Darwin":
    nbsphinx_execute = "auto"
else:
    nbsphinx_execute = "auto"  # force rerun jupyter notebooks for RTD build


# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
#
# html_static_path = ['_static']
# html_context = {
#     'css_files': [
#         '_static/theme_overrides.css',  # override wide tables in RTD theme
#         ],
#      }

# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# The default sidebars (for documents that don't match any pattern) are
# defined by theme itself.  Builtin themes are using these templates by
# default: ``['localtoc.html', 'relations.html', 'sourcelink.html',
# 'searchbox.html']``.
#
# html_sidebars = {}
numfig = True
# html_logo = 'assets/img/SUEWS_LOGO.png'

# -- Options for HTMLHelp output ---------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = "supy_doc"


# -- Options for LaTeX output ------------------------------------------------
# this can be one of ['pdflatex', 'xelatex', 'lualatex', 'platex']
if platform.system() == "Darwin":
    latex_engine = "lualatex"
else:
    latex_engine = "pdflatex"

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #
    # 'papersize': 'letterpaper',
    # The font size ('10pt', '11pt' or '12pt').
    #
    # 'pointsize': '10pt',
    # Additional stuff for the LaTeX preamble.
    #
    "preamble": r"""
\usepackage[titles]{tocloft}
\usepackage{ragged2e}
\addto\captionsenglish{\renewcommand{\bibname}{References}}
\cftsetpnumwidth {1.25cm}\cftsetrmarg{1.5cm}
\setlength{\cftchapnumwidth}{0.75cm}
\setlength{\cftsecindent}{\cftchapnumwidth}
\setlength{\cftsecnumwidth}{1.25cm}
\newcolumntype{T}{L}
\setlength{\tymin}{40pt}
""",
    # Latex figure (float) alignment
    #
    # 'figure_align': 'htbp',
}

latex_show_pagerefs = False

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, "SuPy.tex", doc_name, author, "manual"),
]
# latex_logo = 'assets/img/SUEWS_LOGO.png'

# -- Options for manual page output ------------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, "SuPy", "SuPy Documentation", [author], 1),
]


# -- Options for Texinfo output ----------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (
        master_doc,
        "SuPy",
        "SuPy Documentation",
        author,
        "SuPy",
        "One line description of project.",
        "Miscellaneous",
    ),
]


# -- Options for Epub output -------------------------------------------------

# Bibliographic Dublin Core info.
epub_title = project
epub_author = author
epub_publisher = author
epub_copyright = copyright

# The unique identifier of the text. This can be a ISBN number
# or the project homepage.
#
# epub_identifier = ''

# A unique identification for the text.
#
# epub_uid = ''

# A list of files that should not be packed into the epub file.
epub_exclude_files = ["search.html"]


# -- Extension configuration -------------------------------------------------
# rinoh_documents = [('index',            # top-level file (index.rst)
#                     'target',           # output (target.pdf)
#                     'Document Title',   # document title
#                     'John A. Uthor')]   # document author

# Fix for scrolling tables in the RTD-theme
# https://rackerlabs.github.io/docs-rackspace/tools/rtd-tables.html
def setup(app):
    app.add_css_file("theme_overrides.css")


# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
    "python": ("https://docs.python.org/3/", None),
    "pandas": ("http://pandas.pydata.org/pandas-docs/stable/", None),
    "numpy": ("https://docs.scipy.org/doc/numpy/", None),
    "suews": ("https://suews.readthedocs.io/en/develop/", None),
    "lmfit": ("https://lmfit.github.io/lmfit-py/", None),
}

html_context = {
    "display_github": True,  # Integrate GitHub
    "github_user": "UMEP-dev",  # Username
    "github_repo": "SuPy",  # Repo name
    "github_version": "master",  # Version
    "conf_py_path": "/source/",  # Path in the checkout to the docs root
}


def source_read_handler(app, docname, source):
    if app.builder.format != "html":
        return
    src = source[0]
    # base location for `docname`
    if ('"metadata":' in src) and ('"nbformat":' in src):
        # consider this as an ipynb
        # and do nothing
        return

    # modify the issue link to provide page specific URL
    str_base = "docs/source"
    str_repo = html_context["github_repo"]

    # encode body query to be URL compliant
    str_body = f"""## Issue
<!-- Please describe the issue below this line -->

## Links
[source doc](https://github.com/UMEP-dev/{str_repo}/blob/master/{str_base}/{docname}.rst)
[RTD page](https://suews.readthedocs.org/en/latest/{docname}.html)
"""
    str_query_body = urllib.parse.urlencode({"body": str_body})
    str_url = f"https://github.com/UMEP-dev/{str_repo}/issues/new?assignees=&labels=docs&template=docs-issue-report.md&{str_query_body}&title=[Docs]{docname}"
    str_GHPage = f"""
.. _GitHub Issues: {str_url}
"""
    rendered = "\n".join([str_GHPage, src])
    source[0] = rendered.rstrip("\n")


# Fix for scrolling tables in the RTD-theme
# https://rackerlabs.github.io/docs-rackspace/tools/rtd-tables.html
def setup(app):
    app.connect("source-read", source_read_handler)
    app.add_css_file("theme_overrides.css")
    # Fix equation formatting in the RTD-theme
    app.add_css_file("fix-eq.css")
