# coding: utf-8
require 'spec_helper'

describe 'Conversion' do
  it 'should create a document header with title, author and attributes' do
    input = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<book xmlns="http://docbook.org/ns/docbook">
<info>
<title>Document Title</title>
<author>
<firstname>Doc</firstname>
<surname>Writer</surname>
<email>doc@example.com</email>
</author>
</info>
<section>
<title>First Section</title>
<para>content</para>
</section>
</book>
    EOS

    expected = <<-EOS.rstrip
= Document Title
Doc Writer <doc@example.com>
:doctype: book
:sectnums:
:toc: left
:icons: font
:experimental:

== First Section

content
    EOS

    output = Docbookrx.convert input

    expect(output).to eq(expected)
  end

  it 'should convert guimenu element to menu macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook">File operations are found in the <guimenu>File</guimenu> menu.</para>
    EOS

    expected = 'menu:File[]'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert menuchoice element to menu macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook">Select <menuchoice><guimenu>File</guimenu><guisubmenu>Open Terminal</guisubmenu><guimenuitem>Default</guimenuitem></menuchoice>.</para>
    EOS

    expected = 'menu:File[Open Terminal > Default]'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert link element to uri macro' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <link xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</link> on Wikipedia.</para>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert uri element to uri macro' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <uri xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</uri> on Wikipedia.</para>
<para>All DocBook V5.0 elements are in the namespace <uri>http://docbook.org/ns/docbook</uri>.</para>
</article>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.

All DocBook V5.0 elements are in the namespace http://docbook.org/ns/docbook.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert ulink element to uri macro' do
    input = <<-EOS
<!DOCTYPE para PUBLIC "-//OASIS//DTD DocBook XML V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd">
<para xmlns="http://docbook.org/ns/docbook">Read about <ulink url="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</ulink> on Wikipedia.</para>
    EOS

    expected = 'Read about http://en.wikipedia.org/wiki/Object-relational_mapping[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should use attribute refence for uri if matching uri attribute is present' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">Read about <uri xlink:href="http://en.wikipedia.org/wiki/Object-relational_mapping">Object-relational mapping</uri> on Wikipedia.</para>
    EOS

    expected = 'Read about {uri-orm}[Object-relational mapping] on Wikipedia.'

    output = Docbookrx.convert input, attributes: {
      'uri-orm' => 'http://en.wikipedia.org/wiki/Object-relational_mapping'
    }

    expect(output).to include(expected)
  end

  it 'should convert xref element to xref' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">See <xref linkend="usage"/> for more information.</para>
    EOS

    expected = '<<usage>>'

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to include(expected)
  end

  it 'should use explicit label on xref if provided' do
    input = <<-EOS
<para xmlns="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink">See <xref linkend="usage">Usage</xref> for more information.</para>
    EOS

    expected = '<<usage,Usage>>'

    output = Docbookrx.convert input, normalize_ids: false

    expect(output).to include(expected)
  end

  it 'should convert itemized list to unordered list' do
    input = <<-EOS
<itemizedlist xmlns="http://docbook.org/ns/docbook">
<listitem>
<para>Apples</para>
</listitem>
<listitem>
<para>Oranges</para>
</listitem>
<listitem>
<para>Bananas</para>
</listitem>
</itemizedlist>
    EOS

    expected = <<-EOS.rstrip
* Apples
* Oranges
* Bananas
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert orderedlist to unordered list' do
    input = <<-EOS
<orderedlist xmlns="http://docbook.org/ns/docbook">
<listitem>
<para>Apples</para>
</listitem>
<listitem>
<para>Oranges</para>
</listitem>
<listitem>
<para>Bananas</para>
</listitem>
</orderedlist>
    EOS

    expected = <<-EOS.rstrip
. Apples
. Oranges
. Bananas
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert various types to anonymous literal' do
    input = <<-EOS
<para>
<code>Apples</code>, <command>oranges</command>, <computeroutput>bananas</computeroutput>, <database>pears</database>, <function>grapes</function>, <literal>mangos</literal>, <tag>kiwis</tag>, and <userinput>persimmons</userinput>.
</para>
    EOS

    expected = <<-EOS.rstrip
``Apples``, ``oranges``, ``bananas``, ``pears``, ``grapes``, ``mangos``, ``kiwis``, and ``persimmons``.
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert quote to double quoted text' do
    input = '<para><quote>Apples</quote></para>'

    expected = '"`Apples`"'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert funcsynopsis to C source' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>

<funcsynopsis>
  <funcprototype>
    <?dbhtml funcsynopsis-style='ansi'?>
    <funcdef>int <function>rand</function></funcdef>
    <void/>
 </funcprototype>
</funcsynopsis>

<funcsynopsis>
  <funcsynopsisinfo>
#include &lt;varargs.h&gt;
  </funcsynopsisinfo>
  <funcprototype>
    <?dbhtml funcsynopsis-style='kr'?>
    <funcdef>int <function>max</function></funcdef>
    <varargs/>
  </funcprototype>
</funcsynopsis>

<funcsynopsis>
  <funcprototype>
  <?dbhtml funcsynopsis-style='ansi'?>
    <funcdef>void <function>qsort</function></funcdef>
    <paramdef>void *<parameter>dataptr</parameter>[]</paramdef>
      <paramdef>int <parameter>left</parameter></paramdef>
    <paramdef>int <parameter>right</parameter></paramdef>
      <paramdef>int <parameter>(*comp)</parameter>
      <funcparams>void *, void *</funcparams></paramdef>
  </funcprototype>
</funcsynopsis>

</article>
    EOS

    expected = <<-EOS.rstrip
[source,c]
----
int rand (void);
----

[source,c]
----
#include <varargs.h>

int max (...);
----

[source,c]
----
void qsort (void *dataptr[],
            int left,
            int right,
            int (*comp) (void *, void *));
----
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert note element to NOTE' do
    input = <<-EOS
<note>
  <para>
    Please note the fruit:
    <screen>Apple, oranges and bananas</screen>
  </para>
</note>
    EOS

    expected = <<-EOS.rstrip
[NOTE]
====
Please note the fruit: 
----
Apple, oranges and bananas
----

====
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should accept special section names without title' do
    input = '<bibliography></bibliography>'

    expected = '= Bibliography'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert quandaset elements to Q and A list' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'>
  <qandaset>
    <qandadiv>
      <title>Various Questions</title>
      <qandaentry xml:id="some-question">
      <question>
        <para>My question?</para>
      </question>
      <answer>
        <para>My answer!</para>
      </answer>
      </qandaentry>
    </qandadiv>
  </qandaset>
</article>
    EOS

    expected = <<-EOS.rstrip
.Various Questions

[qanda]
[[_some_question]]
My question?::

My answer!
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert emphasis elements to emphasized text' do
    input = "<para><emphasis>Apple</emphasis> or <emphasis>pine</emphasis>apple.</para>"

    expected = "_Apple_ or __pine__apple"

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert bibliography section to bibliography section' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

<bibliography xml:id="references">
<bibliomixed>
<abbrev>RNCTUT</abbrev>
Clark, James – Cowan, John – MURATA, Makoto: <title>RELAX NG Compact Syntax Tutorial</title>.
Working Draft, 26 March 2003. OASIS. <bibliomisc><link xl:href="http://relaxng.org/compact-tutorial-20030326.html"/></bibliomisc>
</bibliomixed>
</bibliography>

</article>
    EOS

    expected = <<-EOS.rstrip
[bibliography]
[[_references]]
== Bibliography
- [[[RNCTUT]]] 
Clark, James – Cowan, John – MURATA, Makoto: RELAX NG Compact Syntax Tutorial.
Working Draft, 26 March 2003. OASIS. http://relaxng.org/compact-tutorial-20030326.html
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert abbrev and acronym to monospaced' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

<para><acronym>Scuba</acronym> is an acronym while <abbrev>NSA</abbrev> is an abbreviation</para>

</article>
    EOS

    expected = <<-EOS.rstrip
`Scuba` is an acronym while `NSA` is an abbreviation
    EOS

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should deal with incorrect numcols values' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <table>
    <title>Control parameters</title>
    <tgroup cols="5">
      <thead>
        <row>
          <entry>Apple</entry>
          <entry>Bear</entry>
          <entry>Carrot</entry>
          <entry>Dam</entry>
        </row>
      </thead>
    </tgroup>
  </table>
</article>
    EOS
   expected = <<-EOS.rstrip
.Control parameters
[cols="1,1,1,1,1", options="header"]
|===
| Apple
| Bear
| Carrot
| Dam
|===
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert nested program listings in listitems correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <para>Some examples:
    <itemizedlist>
      <listitem>
        <para>get all process definitions</para>
        <para>
          <programlisting>Collection mousse = service.getChocolate();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>get active process instances
          <programlisting>Collection rum = service.getRaisin();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>get tasks assigned to john
          <programlisting>List moonshine = service.getCinnamon();</programlisting>
        </para>
      </listitem>
      <listitem>
        <para>this listitem has....</para>
        <para>...multiple elements!</para>
        <para>So there should be continuations!</para>
    </itemizedlist>
  </para>
</article>
    EOS

    expected = <<-EOS

Some examples: 

* get all process definitions
+
[source]
----
Collection mousse = service.getChocolate();
----

* get active process instances 
+
[source]
----
Collection rum = service.getRaisin();
----

* get tasks assigned to john 
+
[source]
----
List moonshine = service.getCinnamon();
----

* this listitem has....
+ 
...multiple elements!
+ 
So there should be continuations!
   EOS
    expected += " "
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert emphasis bold elements correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <para><emphasis role="bold">Singleton strategy</emphasis>- instructs RuntimeManager to do stuff</para>
</article>
    EOS

    expected = <<-EOS.rstrip
**Singleton strategy**- instructs RuntimeManager to do stuff
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert nested listitems correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <itemizedlist>
    <listitem>
      <para>simple</para>
    </listitem>
    <listitem>
      <para>compact</para>
      <itemizedlist>
        <listitem>
          <para>design</para>
        </listitem>
        <listitem>
          <para>value</para>
        </listitem>
      </itemizedlist>
    </listitem>
    <listitem>
      <para>orcas</para>

      <orderedlist>
        <listitem>
          <para>tuna</para>

          <itemizedlist>
            <listitem>
              <para>squid</para>

              <orderedlist>
                <listitem>
                  <para>shrimp</para>
                </listitem>
              </orderedlist>

            </listitem>
          </itemizedlist>

        </listitem>
        <listitem>
          <para>manta rays</para>
        </listitem>
      </orderedlist>

    </listitem>
  </itemizedlist>
  <para>break!</para>
  <itemizedlist>
    <listitem>
      <para>layer</para>
    </listitem>
    <listitem>
      <para>cake</para>
      <itemizedlist>
        <listitem>
          <para>is a</para>
          <itemizedlist>
            <listitem>
              <para>great film!</para>
            </listitem>
          </itemizedlist>
        </listitem>
      </itemizedlist>
    </listitem>
  <itemizedlist>
</article>
    EOS

    expected = <<-EOS

* simple
* compact
** design
** value
* orcas
.. tuna
*** squid
.... shrimp
.. manta rays


break!

* layer
* cake
** is a
*** great film!
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should add all table lines and escape | characters in table text' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <table>
    <tgroup cols="4"> 
      <thead>
        <row>
          <entry>Name</entry>
          <entry>Possible values</entry>
          <entry>Default value</entry>
          <entry>Description|Identity</entry>
        </row>
      </thead>
      <tbody>
        <row>
          <entry>Tom</entry>
          <entry>true|false|unknown</entry>
          <entry>unknown</entry>
          <entry>The quantum postman</entry>
        </row>
      </tbody>
     </tgroup>
  </table>    
</article>
    EOS

    expected = <<-EOS.rstrip

[cols="1,1,1,1", options="header"]
|===
| Name
| Possible values
| Default value
| Description\\|Identity


|Tom
|true\\|false\\|unknown
|unknown
|The quantum postman
|===
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should correctly nest formatting (bold, emphasized, literal) in text' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
   <itemizedlist>
      <listitem>
        <para><emphasis role="bold">bold</emphasis></para>
      </listitem>
      <listitem>
        <para><code>code</code></para>
      </listitem>
      <listitem>
        <para><emphasis>italics</emphasis></para>
      </listitem>
      <listitem>
        <para>
          <emphasis role="bold">bold, <emphasis>bold italics</emphasis></emphasis><emphasis>, and italics</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis>italics, <emphasis role="bold">italicized bold</emphasis></emphasis><emphasis role="bold">, and bold</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis>empha-<code>\#{code}</code>-sized</emphasis></para>
      </listitem>
      <listitem>
        <para><emphasis role="bold">bold-<code>code</code></emphasis></para>
      </listitem>
      <listitem>
        <para>Really hard to fix elegantly.. and an outer edge case.<!-- <emphasis>Not</emphasis><emphasis role="bold">Bold<emphasis>But<code>Ridiculous</code></emphasis></emphasis> --></para>
      </listitem>
      <listitem>
        <para><code>CodeNormal<emphasis>Italics</emphasis><emphasis role="bold">Bold</emphasis><emphasis><emphasis role="bold">Ridiculous</emphasis></emphasis></code></para>
      </listitem>
      <listitem>
        <para><code>_underscores_in_code_</code></para>
      </listitem>
      <listitem>
        <para><code>*starry*code**</code></para>
      </listitem>
    </itemizedlist>
</article>
    EOS

    expected = <<-EOS.rstrip

* *bold*
* `code`
* _italics_
* **bold, __bold italics__**__, and italics__
* __italics, **italicized bold**__**, and bold**
* _empha-``__\\\#{code}__``-sized_
* *bold-``**code**``*
* Really hard to fix elegantly.. and an outer edge case.
* `CodeNormal__Italics__**Bold**__**Ridiculous**__`
* `\\_underscores_in_code_`
* `\\*starry*code**`
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert escape hashes in literal or formatted text' do
    input = '<para><code><emphasis>#{expression}</emphasis></code></para>'

    expected = '`__\#{expression}__`'

    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should convert bridgeheads without renderas attributes' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">
  <section>
    <title>Section title</title>
    <bridgehead>Section bridgehead</bridgehead>
    <bridgehead renderas="sect3">level-three</bridgehead>

    <section>
      <title>subsub</title>
      <bridgehead>bridgebridge</bridgehead>
      <bridgehead renderas="sect1">level-one</bridgehead>
    </section>

  </section>
</article>
    EOS

    expected = <<-EOS.rstrip

== Section title

[float]
=== Section bridgehead

[float]
==== level-three

=== subsub

[float]
==== bridgebridge

[float]
== level-one
    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

  it 'should process nested admonitions and other things in lists correctly' do
    input = <<-EOS
<article xmlns='http://docbook.org/ns/docbook'
         xmlns:xl="http://www.w3.org/1999/xlink"
         version="5.0" xml:lang="en">

  <itemizedlist>
    <listitem>Simple text</listitem>
    <listitem><emphasis>Not</emphasis> all of the text!</listitem>
    <listitem><para>Simple para</para></listitem>
    <listitem>
        <para>Para between text</para>
    </listitem>
    <listitem>
      <note>
        <para>Note text</para>
      </note>
      <para>List text</para>
    </listitem>
    <listitem>
      <note>
        <para>Two</para>
      </note>
      <note>
        <para>Notes</para>
      </note>
    </listitem>
    <listitem>
      <note>
        <para>One note</para>
      </note>
    </listitem>
    <listitem>
      <para>Craziness: text and then.. </para>
      <note>
        <para>.. a note...</para>
      </note>
      <para>...and then more text?!?</para>
    </listitem>
    <listitem>
      <note>
        <para>.. a note...</para>
      </note>
      <itemizedlist>
        <listitem>
          <para>Crazier</para>
          <itemizedlist>
            <listitem><para>Craziest</para></listitem>
          </itemizedlist>
        </listitem>
      </itemizedlist>
      <para>Crazy</para>
    </listitem>  
  </itemizedlist>

</article>
    EOS

    expected = <<-EOS.rstrip

* Simple text
* _Not_ all of the text!
* Simple para
* Para between text
* {empty}
+

[NOTE]
====
Note text
====
+ 
List text
* {empty}
+

[NOTE]
====
Two
====
+

[NOTE]
====
Notes
====
* {empty}
+

[NOTE]
====
One note
====
* Craziness: text and then.. 
+

[NOTE]
====
$$..$$ a note...
====
+ 
...and then more text?!?
* {empty}
+

[NOTE]
====
$$..$$ a note...
====
** Crazier
*** Craziest

+ 
Crazy

    EOS
    output = Docbookrx.convert input

    expect(output).to include(expected)
  end

end
