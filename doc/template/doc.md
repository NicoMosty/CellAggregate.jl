---
title: "The Document Title"
author: [Example Author, Another Author]
date: "year-month-day"
keywords: [Markdown, Example]
bibliography: export.bib
---
<!---
pandoc --bibliography=export.bib -o doc.pdf doc.md
-->

# Sección 

## Subsección

## Subsubsección

A cite[^1]

Bibliographic Reference [@cristea2020].

# Type of format of the text
*Italic text* 
**bold text** 
~~strikethrough~~	
`courier`

# Block Quotation
> This is a block quotation.  Block quotations are specified by
> proceeding each line with a > character.  The quotation block
> will be indented.
>
> To have paragraphs in block quotations, separate paragraphs
> with a line containing only the block quotation mark character.

[^1]: ¡This is a foot note! and a [link](https://www.eff.org/).

# Code
~~~~
a = rnorm(10,5,2)
for (i in 1:10) {
print(a[1])
}
~~~~

# Bullet List
* This is the first bullet item
* This is the second.  
To indent this sentence on the next line,
the previous line ended in two spaces and
this sentence is indented by four spaces.
* This is the third item

# Ordered List
## Numbered
1. This is the first numbered item.
2. This is the second.
1. This is the third item.  Note that the number I supplied is ignored

# List Ends
1. This is the first numbered item.
2. This is the second.
1. This is the third item.  Note that the number I supplied is ignored

<:!-- -->

1. Another list.
2. With more points

## Non Numbered
(i) This is list with roman numeral enumerators
(ii) Another item

# Definitions
Term 1
:  This is the definition of this term
This is a phrase
:  This is the definition of the phrase

# Horizontal lines (rules)
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Praesent a velit quis ante dignissim dignissim eget vitae tellus. 
Duis eget neque tellus, eu elementum leo. Nullam quis velit 
in magna bibendum dictum. Curabitur tincidunt cursus tellus, 
in egestas augue porta ut. 

* * * *

Phasellus facilisis porttitor elit, vel pretium felis volutpat in. 
Praesent euismod sagittis tortor, eget varius nisi consequat eget. 
Sed facilisis aliquet accumsan. Maecenas aliquam, dolor id hendrerit viverra, 
lacus tortor elementum nunc, quis commodo ligula orci vel augue. Suspendisse 
dolor purus, volutpat vel viverra vitae, laoreet blandit nulla.

---------

In eros ligula, scelerisque id tempus nec, pulvinar vitae felis. Morbi
tempor viverra orci, quis elementum metus lobortis sed. Curabitur sit amet ante massa.

# Table

## Simple Table
Column A    Column B    Column C
---------  ----------  ---------
Category 1    High        100.00
Category 2    High         80.50
---------  ----------  ---------

## Multiline Table
--------------------------------
Column A    Column B      Column 
---------  ----------  ---------
Category 1    High        100.00
   High      95.00

              High         80.50
             82.50

--------------------------------

## Grilled Table
Table: this is the table caption [cap]: #cap

+---------------+---------------+--------------------+
| Fruit         | Price         | Advantages         |
+===============+===============+====================+
| Bananas       | $1.34         | - built-in wrapper |
|               |               | - bright color     |
+---------------+---------------+--------------------+
| Oranges       | $2.10         | - cures scurvy     |
|               |               | - tasty            |
+---------------+---------------+--------------------+

+-----------+----------+-----------+
|Column A   |Column B  |   Column C|
+===========+==========+===========+
|Category 1 |100.00    | - point A |
|           |          | - point B |
+-----------+----------+-----------+
|Category 2 | 85.00    | - point C |
|           |          | - point D |
+-----------+----------+-----------+

## Pipe Table
| Default | left  | Center | Right  |
|---------|:------|:------:|-------:|
|   High  | Cat 1 | A      | 100.00 |
|   High  | Cat 2 | B      |  85.50 |
|   Low   | Cat 3 | C      |  80.00 |

# Math
The formula, $y=mx+c$, is displayed inline. 
Some symbols and equations (such as 
$\sum{x}$ or $\frac{1}{2}$) are rescaled 
to prevent disruptions to the regular 
line spacing.
For more voluminous equations (such as 
$\sum{\frac{(\mu - \bar{x})^2}{n-1}}$), 
some line spacing disruptions are unavoidable.  
Math should then be displayed in displayed mode.
$$\\sum{\frac{(\mu - \bar{x})^2}{n-1}}$$

# Reference
## Internal Links
* See the [introduction](#Sección).
* See the [cap](#cap).


# Bibliography