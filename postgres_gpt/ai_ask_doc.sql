create function ai_ask_doc(doc_table varchar, question varchar, max_token integer = 1024, mode varchar = 'v2')
    returns varchar
as
$$
    import openai

    top_n = 3
    documentation_length = 7800

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

    # v1: Answer the question with the Completion model.
    def bot_v1():
        prompt = f'Documentation:\n{documentation}\nQuestion: {question}\nAnswer:'
        rsp = openai.Completion.create(
            model="text-davinci-003",
            prompt=prompt,
            temperature=0.7,
            max_tokens=max_token
        )
        answer = rsp['choices'][0]['text']
        return answer

    # v2: Answer the question with the ChatCompletion model.
    def bot_v2():
        prompt = f'You are an assistant with the following background knowledge::\n{documentation}'
        rsp = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            temperature=0.7,
            max_tokens=1024,
            messages=[
                {'role': 'system', 'content': prompt},
                {'role': 'user', 'content': question}
            ]
        )
        answer = rsp['choices'][0]['message']['content']
        return answer

    if mode == 'v1':
        return bot_v1()
    elif mode == 'v2':
        return bot_v2()
    else:
        return bot_v2()

$$ language plpython3u;