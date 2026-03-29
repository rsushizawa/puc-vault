-- create
CREATE TABLE usuario(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	nome VARCHAR(75) NOT NULL,
	username VARCHAR(20) NOT NULL UNIQUE,
	email VARCHAR(50) NOT NULL UNIQUE,
	cargo VARCHAR(15),
	status VARCHAR(15) DEFAULT 'ACTIVE',
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	senha_hash TEXT NOT NULL,
	
	CONSTRAINT status_usuario
		CHECK (status IN ('ACTIVE', 'MUTED', 'BANNED'))
);

-- FORUM
CREATE TABLE forum(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	titulo VARCHAR(20) NOT NULL UNIQUE, 
	descricao VARCHAR(100) NOT NULL,
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	status VARCHAR(20) DEFAULT 'WAITING',
	
	criado_por INT NOT NULL,
	validado_por INT NULL,
	
	CONSTRAINT diferentes_usuarios_forum
		CHECK (validado_por IS NULL OR criado_por != validado_por),
	
	CONSTRAINT status_forum
		CHECK (status IN ('WAITING', 'ACTIVE', 'DELETED')),
	
	FOREIGN KEY(criado_por) REFERENCES usuario(id),
	FOREIGN KEY(validado_por) REFERENCES usuario(id)
);

-- TAG
CREATE TABLE tag(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tag VARCHAR(20) NOT NULL UNIQUE,
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	status VARCHAR(20) DEFAULT 'WAITING',
	
	criado_por INT NOT NULL,
	validado_por INT NULL,
	
	CONSTRAINT diferentes_usuarios_tag
		CHECK (validado_por IS NULL OR criado_por != validado_por),
		
	CONSTRAINT status_tag
		CHECK (status IN ('WAITING', 'ACTIVE', 'DELETED')),
	
	FOREIGN KEY(criado_por) REFERENCES usuario(id),
	FOREIGN KEY(validado_por) REFERENCES usuario(id)
);

-- CONTEUDO -> GENERALIZADO
CREATE TABLE conteudo(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	conteudo TEXT NOT NULL,
	status VARCHAR(15) DEFAULT 'PUBLISHED',
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	data_delete TIMESTAMP WITH TIME ZONE,
	criado_por INT NOT NULL,
	
	CONSTRAINT status_conteudo
		CHECK (status IN ('PUBLISHED', 'FIXED', 'DELETED')),
	
	FOREIGN KEY(criado_por) REFERENCES usuario (id)
);

-- CONTEUDO -> POSTAGEM ESPECIALIZADO
CREATE TABLE postagem(
	id INT PRIMARY KEY REFERENCES conteudo(id),
	forum INT REFERENCES forum(id) NOT NULL,
	arquivo BYTEA
);

-- CONTEUDO -> COMENTARIO ESPECIALIZADO
CREATE TABLE comentario(
	id INT PRIMARY KEY REFERENCES conteudo(id),
	postagem_pai INT REFERENCES postagem(id),
	comentario_pai INT REFERENCES comentario(id),
	
	CONSTRAINT conteudo_pai
		CHECK (comentario_pai IS NULL OR postagem_pai IS NOT NULL)
);

-- DENUNCIA -> GENERALIZADO
CREATE TABLE denuncia(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tipo VARCHAR(30) NOT NULL,
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	
	denunciante INT REFERENCES usuario(id) NOT NULL
);

-- DENUNCIA -> DENUNCIA PARA USUARIO ESPECIALIZADO
CREATE TABLE denuncia_usuario(
	id INT PRIMARY KEY REFERENCES denuncia(id),
	usuario_denunciado INT NOT NULL REFERENCES usuario(id)
);

-- DENUNCIA -> DENUNCIA PARA CONTEUDO ESPECIALIZADO
CREATE TABLE denuncia_conteudo(
	id INT PRIMARY KEY REFERENCES denuncia(id),
	conteudo_denunciado INT NOT NULL REFERENCES conteudo(id)
);

--TABELAS AUXILIARES
-- AVALIAÇÃO POSTAGEM (N) <-> USUARIO (N)
CREATE TABLE avaliacao(
	usuario INT NOT NULL REFERENCES usuario(id),
	postagem INT NOT NULL REFERENCES postagem(id),
	valor_avaliacao SMALLINT NOT NULL,

	CONSTRAINT valor_avaliacao
		CHECK (valor_avaliacao IN (1,-1)),

	PRIMARY KEY(usuario, postagem)
);

-- CLASSIFICAÇÃO POSTAGEM (N) <-> TAGS (N)
CREATE TABLE classificacao(
	postagem INT NOT NULL REFERENCES postagem(id),
	tag INT NOT NULL REFERENCES tag(id),
	
	PRIMARY KEY(postagem, tag)
);

-- SEGUE USUARIO (N) <-> FÓRUM (N)
CREATE TABLE segue(
	usuario INT NOT NULL REFERENCES usuario(id),
	forum INT NOT NULL REFERENCES forum(id),
	
	PRIMARY KEY(usuario, forum)
);


-- PROCEDURES
-- USER INSERT PROCEDURE
-- USAGE -> CALL user_insert(<nome>, <nome de usuário>, <email>, <senha codificada>);
CREATE PROCEDURE user_insert (
	p_nome VARCHAR,
	p_username VARCHAR,
	p_email VARCHAR,
	p_senha_hash TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO usuario (nome, username, email, senha_hash)
	VALUES (p_nome, p_username, p_email, p_senha_hash);
END;
$$;

-- FORUM INSERT PROCEDURE
-- USAGE -> CALL forum_insert(<nome do forum>, <descrição do forum>, <id do criador do fórum>);
CREATE PROCEDURE forum_insert (
	p_titulo VARCHAR,
	p_descricao VARCHAR,
	p_criado_por INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO forum (titulo, descricao, criado_por)
	VALUES (p_titulo, p_descricao, p_criado_por);
END;
$$;

-- TAG INSERT PROCEDURE
-- USAGE -> CALL tag_insert(<nome da tag>, <id do criador da tag>);
CREATE PROCEDURE tag_insert (
	p_tag VARCHAR,
	p_criado_por INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO tag (tag, criado_por)
	VALUES (p_tag, p_criado_por);
END;
$$;

-- POSTAGEM INSERT PROCEDURE
-- USAGE -> CALL postagem_insert(<conteudo de texto>, <id do autor>, <id do fórum>, <arquivo (opcional)>);
CREATE PROCEDURE postagem_insert (
	OUT p_id INT,
	p_conteudo TEXT,
	p_criado_por INT,
	p_forum INT,
	p_arquivo BYTEA DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO conteudo (conteudo, criado_por)
	VALUES (p_conteudo, p_criado_por)
	RETURNING id INTO p_id;
	
	INSERT INTO postagem(id, forum, arquivo)
	VALUES (p_id, p_forum, p_arquivo);
END;
$$;

-- COMENTARIO INSERT PROCEDURE
-- USAGE -> CALL comentario_insert(<conteudo de texto>, <id do autor>, <id da postagem comentada/pai>, <id do comentário comentado>);
CREATE PROCEDURE comentario_insert (
	OUT p_id INT,
	p_conteudo TEXT,
	p_criado_por INT,
	p_postagem_pai INT,
	p_comentario_pai INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO conteudo (conteudo, criado_por)
	VALUES (p_conteudo, p_criado_por)
	RETURNING id INTO p_id;
	
	INSERT INTO comentario (id, postagem_pai, comentario_pai)
	VALUES (p_id, p_postagem_pai, p_comentario_pai);
END;
$$;

-- DENUNCIA p/ USUARIO INSERT PROCEDURE
-- USAGE -> CALL denuncia_usuario_insert(<motivador/tipo da denúncia>, <id do autor da denuncia>, <id do usuario que recebeu a denuncia>);
CREATE PROCEDURE denuncia_usuario_insert (
	OUT p_id INT,
	p_tipo VARCHAR,
	p_denunciante INT,
	p_usuario_denunciado INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO denuncia (tipo, denunciante)
	VALUES (p_tipo, p_denunciante)
	RETURNING id INTO p_id;
	
	INSERT INTO denuncia_usuario (id, usuario_denunciado)
	VALUES (p_id, p_usuario_denunciado);
END;
$$;

-- DENUNCIA p/ CONTEUDO INSERT PROCEDURE
-- USAGE -> CALL denuncia_conteudo_insert(<motivador/tipo da denúncia>, <id do autor da denuncia>, <id do conteudo que recebeu a denuncia>);
CREATE PROCEDURE denuncia_conteudo_insert(
	OUT p_id INT,
	p_tipo VARCHAR,
	p_denunciante INT,
	p_conteudo_denunciado INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO denuncia (tipo, denunciante)
	VALUES (p_tipo, p_denunciante)
	RETURNING id INTO p_id;
	
	INSERT INTO denuncia_conteudo (id, conteudo_denunciado)
	VALUES (p_id, p_conteudo_denunciado);
END;
$$;

-- AVALIAR POSTAGEM
-- USAGE -> CALL avaliar_postagem(<id do usuario que realiza a ação>, <id da postagem que recebe a avaliação>, <se 1, upvote, se -1, downvote>);
CREATE PROCEDURE avaliar_postagem (
	p_usuario INT,
	p_postagem INT,
	p_valor_avaliacao SMALLINT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO avaliacao (usuario, postagem, valor_avaliacao)
	VALUES (p_usuario, p_postagem, p_valor_avaliacao);
END;
$$;

-- CLASSIFICAR POSTAGEM
-- USAGE -> CALL classificar_postagem(<id da postagem>, <id da tag>);
CREATE PROCEDURE classificar_postagem (
	p_postagem INT,
	p_tag INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO classificacao (postagem, tag)
	VALUES (p_postagem, p_tag);
END;
$$;

-- SEGUIR FORUM
-- USAGE -> CALL seguir_forum(<id do usuário>, <id do fórum>);
CREATE PROCEDURE seguir_forum (
	p_usuario INT,
	p_forum INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO segue (usuario, forum)
	VALUES (p_usuario, p_forum);
END;
$$;


-- VALIDAR FÓRUM
-- USAGE -> CALL validar_forum(<id usuário que vai validar o fórum>, <fórum a ser validado>);
CREATE PROCEDURE validar_forum (
	p_validador INT,
	p_validado INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE forum
	SET
		status = 'ACTIVE',
		validado_por = p_validador
	WHERE id = p_validado;
END;
$$;

-- VALIDAR TAG
-- USAGE -> CALL validar_tag(<id do usuário que vai validar>, <tag a ser validada>);
CREATE PROCEDURE validar_tag (
	p_validador INT,
	p_validado INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE tag
	SET
		status = 'ACTIVE',
		validado_por = p_validador
	WHERE id = p_validado;
END;
$$;

-- popular o BD
DO $$
DECLARE
    i INT;

    v_user_ids   INT[] := '{}';
    v_forum_ids  INT[] := '{}';
    v_tag_ids    INT[] := '{}';
    v_post_ids   INT[] := '{}';

    v_id INT;

    v_username TEXT;
    v_forum_title TEXT;
    v_tag_name TEXT;
BEGIN
    -- usuários
    FOR i IN 1..10 LOOP
        v_username := 'user' || i;

        CALL user_insert(
            'User ' || i,
            v_username,
            v_username || '@email.com',
            'hash' || i
        );

        SELECT id INTO v_id
        FROM usuario
        WHERE username = v_username;

        v_user_ids := array_append(v_user_ids, v_id);
    END LOOP;

    -- fóruns
    FOR i IN 1..10 LOOP
        v_forum_title := 'Forum ' || i;

        CALL forum_insert(
            v_forum_title,
            'Descricao ' || i,
            v_user_ids[i]
        );

        SELECT id INTO v_id
        FROM forum
        WHERE titulo = v_forum_title;

        v_forum_ids := array_append(v_forum_ids, v_id);
    END LOOP;

    -- tags
    FOR i IN 1..10 LOOP
        v_tag_name := 'tag' || i;

        CALL tag_insert(
            v_tag_name,
            v_user_ids[i]
        );

        SELECT id INTO v_id
        FROM tag
        WHERE tag = v_tag_name;

        v_tag_ids := array_append(v_tag_ids, v_id);
    END LOOP;

    -- postagens
    FOR i IN 1..10 LOOP
        CALL postagem_insert(
            'Conteudo ' || i,
            v_user_ids[i],
            v_forum_ids[i],
            NULL,
            v_id
        );

        v_post_ids := array_append(v_post_ids, v_id);
    END LOOP;

    -- comentários
    FOR i IN 1..10 LOOP
        CALL comentario_insert(
            'Comentario ' || i,
            v_user_ids[i],
            v_post_ids[i],
            NULL,
            v_id
        );
    END LOOP;

    -- denúncia de usuário
    FOR i IN 1..10 LOOP
        CALL denuncia_usuario_insert(
            'tipo' || i,
            v_user_ids[i],
            v_user_ids[(i % 10) + 1],
            v_id
        );
    END LOOP;

    -- denúncia de conteúdo
    FOR i IN 1..10 LOOP
        CALL denuncia_conteudo_insert(
            'tipo_c' || i,
            v_user_ids[i],
            v_post_ids[i],
            v_id
        );
    END LOOP;

    -- avaliações
    FOR i IN 1..10 LOOP
        CALL avaliar_postagem(
            v_user_ids[i],
            v_post_ids[i],
            CASE WHEN i % 2 = 0 THEN -1 ELSE 1 END
        );
    END LOOP;

    -- classificação
    FOR i IN 1..10 LOOP
        CALL classificar_postagem(
            v_post_ids[i],
            v_tag_ids[i]
        );
    END LOOP;

    -- seguir fórum
    FOR i IN 1..10 LOOP
        CALL seguir_forum(
            v_user_ids[i],
            v_forum_ids[i]
        );
    END LOOP;

END $$;

-- updates
DO $$
DECLARE
    i INT;

    v_user_ids   INT[] := '{}';
    v_forum_ids  INT[] := '{}';
    v_tag_ids    INT[] := '{}';

    v_id INT;
BEGIN
    -- carregar usuários
    FOR v_id IN SELECT id FROM usuario ORDER BY id LOOP
        v_user_ids := array_append(v_user_ids, v_id);
    END LOOP;

    -- carregar fóruns
    FOR v_id IN SELECT id FROM forum ORDER BY id LOOP
        v_forum_ids := array_append(v_forum_ids, v_id);
    END LOOP;

    -- carregar tags
    FOR v_id IN SELECT id FROM tag ORDER BY id LOOP
        v_tag_ids := array_append(v_tag_ids, v_id);
    END LOOP;

    -- validar fóruns
    FOR i IN 1..array_length(v_forum_ids, 1) LOOP
        CALL validar_forum(
            v_user_ids[(i % array_length(v_user_ids, 1)) + 1],
            v_forum_ids[i]
        );
    END LOOP;

    -- validar tags
    FOR i IN 1..array_length(v_tag_ids, 1) LOOP
        CALL validar_tag(
            v_user_ids[(i % array_length(v_user_ids, 1)) + 1],
            v_tag_ids[i]
        );
    END LOOP;

END $$;

-- selects
-- usuario
SELECT *
FROM usuario;

-- forum + criador + validador
SELECT 
    f.*,
    u1.username AS criado_por_username,
    u2.username AS validado_por_username
FROM forum f
JOIN usuario u1 ON f.criado_por = u1.id
LEFT JOIN usuario u2 ON f.validado_por = u2.id;

-- tag + criador + validador
SELECT 
    t.*,
    u1.username AS criado_por_username,
    u2.username AS validado_por_username
FROM tag t
JOIN usuario u1 ON t.criado_por = u1.id
LEFT JOIN usuario u2 ON t.validado_por = u2.id;

-- postaegm + conteudo + forum
SELECT 
    c.id,
    c.conteudo,
    c.status,
    c.data_criacao,
    u.username AS autor,
    f.titulo AS forum,
    p.arquivo
FROM postagem p
JOIN conteudo c ON p.id = c.id
JOIN usuario u ON c.criado_por = u.id
JOIN forum f ON p.forum = f.id;

-- conteudo + comentario + postagem pai
SELECT 
    c.id,
    c.conteudo,
    c.data_criacao,
    u.username AS autor,
    cm.postagem_pai,
    cm.comentario_pai
FROM comentario cm
JOIN conteudo c ON cm.id = c.id
JOIN usuario u ON c.criado_por = u.id;

-- denuncia usuario
SELECT 
    d.id,
    d.tipo,
    d.data_criacao,
    u1.username AS denunciante,
    u2.username AS denunciado
FROM denuncia_usuario du
JOIN denuncia d ON du.id = d.id
JOIN usuario u1 ON d.denunciante = u1.id
JOIN usuario u2 ON du.usuario_denunciado = u2.id;

-- denuncia conteudo
SELECT 
    d.id,
    d.tipo,
    d.data_criacao,
    u.username AS denunciante,
    c.conteudo AS conteudo_denunciado
FROM denuncia_conteudo dc
JOIN denuncia d ON dc.id = d.id
JOIN usuario u ON d.denunciante = u.id
JOIN conteudo c ON dc.conteudo_denunciado = c.id;

-- avaliacao + usuario + conteudo + postagem
SELECT 
    u.username,
    c.conteudo,
    a.valor_avaliacao
FROM avaliacao a
JOIN usuario u ON a.usuario = u.id
JOIN postagem p ON a.postagem = p.id
JOIN conteudo c ON p.id = c.id;

-- classificação
SELECT 
    c.conteudo,
    t.tag
FROM classificacao cl
JOIN postagem p ON cl.postagem = p.id
JOIN conteudo c ON p.id = c.id
JOIN tag t ON cl.tag = t.id;

-- follow
SELECT 
    u.username,
    f.titulo
FROM segue s
JOIN usuario u ON s.usuario = u.id
JOIN forum f ON s.forum = f.id;