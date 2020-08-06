% NOG(1) nog 1.1
% Miguel Mejía Jiménez
% August 2020

# NAME 

nog - Notes Generator

# SYNOPSIS

**nog** [OPTIONS] [FILES]

# DESCRIPTION

Reads in order a list of files and processes them in several steps to generate a pdf file via *pdflatex*.

- First step: *nogpre* is called. It determines if the table of contents will be generated and makes the list of **keywords** and **fixme** (see options **-g** and **-f**).
- Second step: *noglex* is called. The translation to LaTex from the files is done.
- Third step: *pdflatex -draftmode*. Creates the auxiliary files, prior to the pdf itself.
- Fourth step: *pdflatex*. The pdf is finally generated.

# OPTIONS

**-a** *author*
: Set the author of the notes and pass it to the \author LaTex command.By default it is empty.

**-t** *title*
: Set the title of the notes and pass  it to the \title LaTex command. By default it is "Notes".

**-d**
: Add the date to the generated notes. By default, the date is empty.

**-o** *file*
: Name of the output file without the pdf extension. By default it is "Notes".

**-s**, **--save**
: Save temporal files (including the .tex) in a directory called **nogtmp**. This option is useful if you want to look for the LaTex errors yourself or edit the output LaTex in an editor of your choice.

**-g**
: Add an appendix with the glossary, which contains a list of the **keywords** of each **unit**.

**-f**
: Add an appendix with the list of **fixme** for each **unit**.

**-k** *timeout*
: Kill *pdflatex* after *timeout* seconds, if it doesn't compile. By default it is 5 (seconds).

**-l** *language*
: Sets the language for the LaTex package babel.

# EXAMPLES

nog -l english -t "Advanced Calculus" -a "Miguel M. J." -o "calculus" lesson1.txt lesson2.txt

nog -f MyNotesWIP.txt

nog -t 10 -g "My long subject"

**Note** that the options always go after the input files.