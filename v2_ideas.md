

# Some ideas

- Merge with an extremely streamlined version of -estout-
- I want the code to be SMALL so it can be extended easily
- Decouple the part where I save estimates with the part where I process them. If no path exists, just use the active/stored estimates
- Do it in Mata??
- Underlying everything write a Table writer?!??! A la R's stargazer? So I have an underlying "table grammar":
  * colheader
  * rowheader
  * common footnotes
  * specific footnotes
  * stats at the end (maybe 1+ blocks)
  * title/subtitle/notes?
- Also the entire `.tsv` thing is a PITA. Replace it with more yaml?

# Markdown link

Allow an `estimates` block that is just YAML that gets converted into a Python dict, which then gets converted into the quipu options.
For instance, title: .. ends up as title(..) and someopt: true ends up as someopt (without parens)

EG:

```stata.estimates
description/comments: Just for me # COmments also like this
title: ...
criteria: ...
from/using: ... OVERRIDES yaml on top
source: 
header: ..
metadata:
  additonal metadata gets passed in metadata(..)
  ..
stats: ...
rename: ...
test: true # This will i) run a -quipu tab- before, and also only run -this- table so we can debug it
```

to avoid strings that are too long on the criteria part, maybe we can do

```yaml
criteria:
 - ...
 - ...
 - ...
```

After all estimates are parsed, a do file is created and run


Also in the initial yaml, we need

stata.estimates.reload-index = true
stata.estimates.update-labels = true
stata.estimates.path.source = PATH
stata.estimates.path.output = PATH


# Bugs/Improvements
- Link stats (F, those in ivreg like KP, J) with their PValues and compute the stars
- 

