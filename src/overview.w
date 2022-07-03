.. py-web-tool/src/overview.w 

Architecture and Design Overview
================================

This application breaks the overall problem of literate programming into the following sub-problems.

1.	Representation of the WEB document as Chunks and Commands

2.	Reading and parsing the input WEB document.

3.	Weaving a document file.

4. 	Tangling the desired program source files.

Here's the overall Context Diagram for this.

..  image:: context.png

Since this runs as part of an Development
Environment, the container is the developer's desktop.

Here's a summary of the components.

..  image:: components.png

The ``weave`` and ``tangle`` are convenient
scripts that invoke the underlying ``pyweb`` application.
This uses Jinja2 to define the various templates
for weaving the output documents.

Overall Code
-------------

Generally, the code breaks into three functional areas

-   The core representation of a WEB

-   The parser to read the source WEB

-   The emitters to produce woven and tangled output, which include weavers and tanglers.

We'll look at the core model, first.

Core WEB Representation
-----------------------



The basic structure has three layers, as shown in the following diagram:

..  image:: code_model.png
    :width: 6in
 
The source document is transformed into a ``Web``, 
which is the overall container. The source is
decomposed into a sequence of ``Chunk`` instances.  Each ``Chunk`` is a sequence
of ``Commands``. 

``Chunk`` objects and ``Command`` objects cannot be nested, leading to delightful simplification.

The overall ``Web``
includes both the original sequence of ``Chunk`` objects as well as an index for the named ``Chunk`` instances.

Note that a named chunk may be created through a number of ``@@d`` commands.
This means that
each named ``Chunk`` may be a sequence of definitions sharing a common name.
They are concatenated in order to permit decomposing a single concept into sequentially described pieces.
 
The various layers of ``Web``, ``Chunk``, and ``Command`` each have attributes designed
to be usable by a Jinja template when weaving output. When tangling, however, the only 
attribute that matters is the text contained in the ``@@{`` and ``@@}`` brackets.
This makes tangling somewhat simpler than weaving. 

There is a small interaction between a ``Tangler`` and each ``Chunk`` to work out the indentation.
based in the context in which a ``@@< name @@>`` reference occurs.

Reading and Parsing
--------------------

..  image:: code_parser.png

A solution to the reading and parsing problem depends on a convenient 
tool for breaking up the input stream and a representation for the chunks of input 
and the sequence of commands.
Input decomposition is done with something we might call the **Splitter** design pattern. 

The **Splitter** pattern is widely used in text processing, and has a long legacy
in a variety of languages and libraries.  A **Splitter** decomposes a string into
a sequence of strings using some split pattern.  There are many variant implementations.
For example, one variant locates only a single occurence (usually the left-most); this is
commonly implemented as a Find or Search string function.  Another variant locates all
occurrences of a specific string or character, and discards the matching string or
character. 

The variation on **Splitter** in this application
creates each element in the resulting sequence as either (1) an instance of the 
split regular expression or (2) the text between split patterns.  

We define our splitting pattern with the regular
expression ``'@@.|\n'``.  This will split on either of these patterns:

-	 ``@@`` followed by a single character,

-	or, a newline.

For the most part, ``\n`` is only text, and as almost no special significance. The exception is the 
``@@i`` *filename* command, which ends at the end of the line, making the ``\n``
significant syntax in this case.

We could be more specific with the following as a split pattern:
``'@@[doOifmu\|<>(){}\[\]]|\n'``.  This would silently ignore unknown commands, 
merging them in with the surrounding text.  This would leave the ``'@@@@'`` sequences 
completely alone, allowing us to replace ``'@@@@'`` with ``'@@'`` in
every text chunk. It's not clear this additional level of detail is helpful.

Within the ``@@d`` and ``@@o`` commands, there is a name and options. These follow
the syntax rules for Tcl or the shell. Optional fields are prefaced with ``-``.
All options must come before all positional arguments. The positional arguments
provide the name being defined. In effect, the name is ``' '.join(args.split(' ')``; 
this means multiple adjacent spaces in a name will be collapsed to a single space.

Emitters
--------

There are two possible outputs:

-   A woven document.

-   One or more tangled source files.

The overall structure of the classes is shown in the following diagram.

..  image:: code_emitter.png

We'll look at weaving first, then tangling.

Weaving
---------

The weaving operation depends on having a target document markup language.
There are several approaches to this problem.  

-   We can use a markup language unique to **py-web-tool**.
    This would hide the final target markup language. It would mean
    that **py-web-tool** would be equivalent to a tool like Pandoc, 
    producing a variety of target markup languages from a single, common source.
	
-   We can use any of the existing markup languages (HTML, RST, Markdown, LaTeX, etc.) 
    expand snippets of markup into author-supplied markup to create the 
    target woven document.

The problem with the first method is defining yet-another-markup-language.
This seems needlessly complex.

The problem with the second method is the source WEB file is a mixture of the following two things:

-   The background document in some standard markup and 

-   The code elements.

The code elements must be set off from the background text via some markup. In languages
like RST and Markdown, there's a small textual wrapper around code samples. In languages
like HTML, the wrapper can be much more complex. Also, certain code characters may need to be
properly escaped if the code sample happens to contain markup that should **not** be processed,
but treated as literal text.

The author should not be foreced to repeat the wrappers around each code examples. 
This should be delegated to the literate programming tool.
Further, the author should not be narrowly constrained by the markup injected
by the weaving process; the weaver should be extensible to add features. 

This leads to using the **Facade** design pattern. The weaver is
a **Facade** over the Jinja template engine. The tool provides default
templates in RST, HTML, and LaTeX. These can be replaced; new templates
can be added. The templates used to wrap code sections can be tweaked relatively easily.


Tangling
----------

The tangling operation produces output files.  In other tools,
some care was taken to understand the source code context for tangling, and
provide a correct indentation.  This required a command-line parameter
to turn off indentation for languages like Fortran, where identation
is not used.  

In **py-web-tool**, there are two options. The default behavior is that the
indent of a ``@@< name @@>`` command is used to set the indent of the 
material is expanded in place of this reference.  If all ``@@<`` commands are presented at the
left margin, no indentation will be done.  This is helpful simplification,
particularly for users of Python, where indentation is significant.

In rare cases, we might need both, and a ``@@d`` chunk can override the indentation
rule to force the material to be placed at the left margin.

Application
------------

The overall application has the following layers to it:
    
-   An ``Action`` class hierarchy that includes the actions of Load, Tangle, and Weave.

-   An overall ``Application`` class that executes the actions.

-   A top-level main function parses the command line, creates and configures the actions, and executes the sequence
    of actions.
    
The idea is that the Weaver Action should be visible to tools like `PyInvoke <https://docs.pyinvoke.org/en/stable/index.html>`_.
We want ``Weave("someFile.w")`` to be a sensible task.  

..  image:: code_application.png

This shows the essential structure of the top-level classes.
