CREATE TABLE companies
(
    id         bigint                      NOT NULL,
    name       text                        NOT NULL,
    image_url  text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE TABLE campaigns
(
    id                    bigint                      NOT NULL,
    company_id            bigint                      NOT NULL,
    name                  text                        NOT NULL,
    cost_model            text                        NOT NULL,
    state                 text                        NOT NULL,
    monthly_budget        bigint,
    blacklisted_site_urls text[],
    created_at            timestamp without time zone NOT NULL,
    updated_at            timestamp without time zone NOT NULL
);

CREATE TABLE ads
(
    id                bigint                      NOT NULL,
    company_id        bigint                      NOT NULL,
    campaign_id       bigint                      NOT NULL,
    name              text                        NOT NULL,
    image_url         text,
    target_url        text,
    impressions_count bigint DEFAULT 0,
    clicks_count      bigint DEFAULT 0,
    created_at        timestamp without time zone NOT NULL,
    updated_at        timestamp without time zone NOT NULL
);


CREATE TABLE paimon
(
    path      varchar,
    content   varchar,
    embedding vector(1536)
);

COPY companies (id, name, image_url, created_at, updated_at)
    FROM '/opt/gpt/dataset/companies.csv'
    DELIMITER ','
    CSV HEADER;

COPY campaigns (id, company_id, name, cost_model, state, monthly_budget, blacklisted_site_urls, created_at, updated_at)
    FROM '/opt/gpt/dataset/campaigns.csv'
    DELIMITER ','
    CSV HEADER;

COPY ads (id, company_id, campaign_id, name, image_url, target_url, impressions_count, clicks_count, created_at,
          updated_at)
    FROM '/opt/gpt/dataset/ads.csv'
    DELIMITER ','
    CSV HEADER;

COPY paimon (path, content, embedding)
    FROM '/opt/gpt/dataset/paimon.csv'
    DELIMITER ','
    CSV HEADER;