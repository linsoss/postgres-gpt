create function ai_embedding_text(text varchar, max_content_length integer = 8000)
    returns vector(1536)
as
$$
    import openai

    _text = text.replace("\n", " ")[0:max_content_length]
    rsp = openai.Embedding.create(input=_text, model="text-embedding-ada-002")
    return rsp['data'][0]['embedding']

$$ language plpython3u;



