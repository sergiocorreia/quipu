# Main

- allow some rows to have a special format (e.g. those close to zero that don't matter much)

# Secondary

- Clean up header lines for complex cases
- Allow multirow
- Check what's in makethesis.py tables.ado (en aug) filter.py (en Research/latex/pandoc)
- Add suboption fmt to header.. so I can do header(.. horizon, fmt(horizon "@ mo."))

# Done
- rotate/size/pagebreak option for pdf output
- Automate vcvnotes and starnotes

# Add to help

stats(default)
stats(..)
stats(, Fmt(key val key val) Labels(k v k v))

header(a b c)

metadata(a.b.c "foo")

orientation() size(#) pagebreak
cellformat(b2(..) se(..))
colformat: used in \begin{longtable}{l*{@M}{`colformat'}}
    // Alternatives include 1) D{.}{.}{-1} with dcolumn 2) c 3) p{2cm} 4) C{2cm} with array + a custom cmd

