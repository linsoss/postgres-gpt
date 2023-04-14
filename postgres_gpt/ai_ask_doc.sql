create function ai_ask_doc(doc_table varchar, question varchar, max_token integer = 256)
    returns varchar
as
$$
    top_n = 3
    documentation_length = 7500

    # Get question text embedding vector
    qst_emb_plan = plpy.prepare('select ai_embedding_text($1)', ['varchar'])
    qst_vector = plpy.execute(qst_emb_plan, [question], 1)[0]['ai_embedding_text']

    # Get the section record with the closest cosine distance
    nearest_dist_plan = plpy.prepare(f'select * from {doc_table} order by embedding <=> $1 limit {top_n}', ['vector'])
    nearest_sections = plpy.execute(nearest_dist_plan, [qst_vector])

    # Merge background documents
    documentation = ''
    for section in nearest_sections:
        documentation += section['content'] + '\n'
    documentation = documentation[:documentation_length]

    prompt = f'Documentation:\n{documentation}\nQuestion: {question}\nAnswer:'

    # Complete the prompt via openai
    answer_plan = plpy.prepare('select ai_text_completion($1, $2)', ['varchar', 'integer'])
    answer = plpy.execute(answer_plan, [prompt, max_token], 1)[0]['ai_text_completion']

    return answer

$$ language plpython3u;