-- Split all markdowns in the specified directory into embedding vectors。

create function ai_embedding_doc(doc_dir varchar, doc_table varchar)
    returns integer
as
$$
    import os
    from markdown_it import MarkdownIt

    def parse_md(file_path) -> list[str]:
        min_section_length = 1024

        with open(file_path, 'r', encoding='utf-8') as f:
            md_data = f.read()
            md = MarkdownIt('commonmark')
            tokens = md.parse(md_data)

            #  Split into sections based on heading.
            sections = []
            cur_section = ''

            for token in tokens:
                if token.type == 'heading_open':
                    if len(cur_section) == 0:
                        cur_section = token.content
                    else:
                        sections.append(cur_section)
                        cur_section = ''
                else:
                    cur_section += token.content

            if len(cur_section) > 0:
                sections.append(cur_section)

            #  Combine sections with a length less than the minimum length with the previous section.
            combined_sections = []
            prev_section = ''

            for section in sections:
                if len(prev_section) == 0:
                    prev_section = section
                elif len(prev_section) + len(section) < min_section_length:
                    prev_section = section
                else:
                    combined_sections.append(prev_section)
                    prev_section = section

            if len(prev_section) == 0:
                combined_sections.append(prev_section)

        return combined_sections

    # Step-1: Parse all markdown files in the given directory.
    file_count = 0
    sections_count = 0
    collected_sections = []

    for root, dirs, files in os.walk(doc_dir):
        for file in files:
            if file.endswith(".md"):
                file_count += 1
                fpath = os.path.join(root, file)
                sections = parse_md(fpath)
                for section in sections:
                    sections_count += 1
                    collected_sections.append({'path': fpath, 'section': section})

    # Step-2: Insert sections data into the target table;
    plpy.execute(f"create table if not exists {doc_table}(path varchar, content varchar, embedding vector(1536))")
    plan = plpy.prepare(f"insert into {doc_table}(path, content) values($1,$2)", ['varchar', 'varchar'])
    for section in collected_sections:
        plpy.execute(plan, [section['path'], section['section']])

    # Step-3: Generate embedding for each section.
    plpy.execute(f'update {doc_table} set embedding = ai_embedding_text(content, 8000) where embedding is null')

    return sections_count

$$ language plpython3u;