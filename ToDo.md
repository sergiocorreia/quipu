

- The paragraphs inside headers (due to the underlines) are making the cells too tall. It's because the top/bottom margins.
- If there is a quote in the table (e.g. if i set stats(cmdline) ) then it gets trunkaed at the quote. Maybe I need compound quotes somewhere.
- If model is iv BUT the stage is not iv, then I want to show r2 and other stats.. although i'm not sure that's what's going on..


## Critical

- Why am I still setting varlabels() for variables that stay the same?!??! EG:  varlabels( ALL_entry_store `"ALL_entry_store"' ..
- Why doesn't rename complain if i have an ODD number of items?
- Fix -quipu use- and -quipu index- so that -index- creates `_path_` and -use- creates `path` (or replace in case someone saves and the var already exists).
- Add `qui` to `replace path...` in `quipu use`
- Why is `note()` (or `footnote`) not working? Also all those footnotes look like crap, need a way to disable when I want to. EG: `nofootnotes`.
- Also, need to make a distintion between i) notes I add, ii) regression notes (like clustering, etc.) and iii) variable footnotes.
- Dar una opcion para que no dropee los estimates al final
- What is this? "sunatConstanttr_yoy_growth" I replaced _cons -> Constant but that also replaced sunat_construction

## Important

- I need a way to add labels to a header. Since the variable exist, one option is to set it as header and use that. Also use varlabel for those (not just label values).
