-- Generate the corresponding query sql based on the natural language,
-- using the metadata in the specified schema.

create function ai_to_sql(prompt varchar, schema varchar = 'public')
    returns varchar
as
$$
    import openai

    # Get all table columns metadata in the schema
    plan = plpy.prepare(
        'select table_name, column_name, data_type from information_schema.columns where table_schema = $1',
        ['varchar'])
    rs = plpy.execute(plan, [schema])

    # Group by table.
    table_metas = {}
    for col_meta in rs:
        if col_meta['table_name'] not in table_metas:
            table_metas[col_meta['table_name']] = []
        else:
            table_metas[col_meta['table_name']].append((col_meta['column_name'], col_meta['data_type']))

    # Generate system prompt
    table_ddl = ''
    for meta in table_metas:
        table_ddl += 'create table ' + meta + ' ('
        for col in table_metas[meta]:
            table_ddl += col[0] + ' ' + col[1] + ','
        table_ddl += ");\n"

    system_prompt = f'You are a PostgreSQL database with the following table structure. \
    Your answer can only be SQL. If the table structures cannot fulfill your answer, \
    please respond with "The database does not contain the table data you are looking for : ) "\n{table_ddl}'

    user_prompt = f'Please answer me briefly with SQL code, just sql content: {prompt}'

    # Request openai ChatCompletion api.
    rsp = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        temperature=0.7,
        max_tokens=1024,
        messages=[
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ]
    )
    answer = rsp['choices'][0]['message']['content']
    return answer

$$ language plpython3u;