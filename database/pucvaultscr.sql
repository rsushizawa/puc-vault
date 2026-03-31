-- tabelas -> private.
-- create
-- identidade visual
CREATE TABLE private.identidade_visual(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	img_perfil TEXT,		-- UNIQUE ID ON CLOUDFLARE IMAGES API
	img_banner TEXT,		-- UNIQUE ID ON CLOUDFLARE IMAGES API
	
	img_perfil_modificado_em TIMESTAMP WITH TIME ZONE,
	img_banner_modificado_em TIMESTAMP WITH TIME ZONE
);

CREATE TABLE private.usuario(
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
CREATE TABLE private.forum(
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
	
	FOREIGN KEY(criado_por) REFERENCES private.usuario(id),
	FOREIGN KEY(validado_por) REFERENCES private.usuario(id)
);

-- TAG
CREATE TABLE private.tag(
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
	
	FOREIGN KEY(criado_por) REFERENCES private.usuario(id),
	FOREIGN KEY(validado_por) REFERENCES private.usuario(id)
);

-- CONTEUDO -> GENERALIZADO
CREATE TABLE private.conteudo(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	conteudo TEXT NOT NULL,
	status VARCHAR(15) DEFAULT 'PUBLISHED',
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	data_delete TIMESTAMP WITH TIME ZONE,
	criado_por INT NOT NULL,
	
	CONSTRAINT status_conteudo
		CHECK (status IN ('PUBLISHED', 'FIXED', 'DELETED')),
	
	FOREIGN KEY(criado_por) REFERENCES private.usuario (id)
);

-- CONTEUDO -> POSTAGEM ESPECIALIZADO
CREATE TABLE private.postagem(
	id INT PRIMARY KEY REFERENCES private.conteudo(id),
	forum INT REFERENCES private.forum(id) NOT NULL,
	arquivo BYTEA
);

-- CONTEUDO -> COMENTARIO ESPECIALIZADO
CREATE TABLE private.comentario(
	id INT PRIMARY KEY REFERENCES private.conteudo(id),
	postagem_pai INT REFERENCES private.postagem(id),
	comentario_pai INT REFERENCES private.comentario(id),
	
	CONSTRAINT conteudo_pai
		CHECK (comentario_pai IS NULL OR postagem_pai IS NOT NULL)
);

-- DENUNCIA -> GENERALIZADO
CREATE TABLE private.denuncia(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tipo VARCHAR(30) NOT NULL,
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	
	denunciante INT REFERENCES private.usuario(id) NOT NULL
);

-- DENUNCIA -> DENUNCIA PARA USUARIO ESPECIALIZADO
CREATE TABLE private.denuncia_usuario(
	id INT PRIMARY KEY REFERENCES private.denuncia(id),
	usuario_denunciado INT NOT NULL REFERENCES private.usuario(id)
);

-- DENUNCIA -> DENUNCIA PARA CONTEUDO ESPECIALIZADO
CREATE TABLE private.denuncia_conteudo(
	id INT PRIMARY KEY REFERENCES private.denuncia(id),
	conteudo_denunciado INT NOT NULL REFERENCES private.conteudo(id)
);

--TABELAS AUXILIARES
-- AVALIAÇÃO POSTAGEM (N) <-> USUARIO (N)
CREATE TABLE private.avaliacao(
	usuario INT NOT NULL REFERENCES private.usuario(id),
	postagem INT NOT NULL REFERENCES private.postagem(id),
	valor_avaliacao SMALLINT NOT NULL,

	CONSTRAINT valor_avaliacao
		CHECK (valor_avaliacao IN (1,-1)),

	PRIMARY KEY(usuario, postagem)
);

-- CLASSIFICAÇÃO POSTAGEM (N) <-> TAGS (N)
CREATE TABLE private.classificacao(
	postagem INT NOT NULL REFERENCES private.postagem(id),
	tag INT NOT NULL REFERENCES private.tag(id),
	
	PRIMARY KEY(postagem, tag)
);

-- SEGUE USUARIO (N) <-> FÓRUM (N)
CREATE TABLE private.segue(
	usuario INT NOT NULL REFERENCES private.usuario(id),
	forum INT NOT NULL REFERENCES private.forum(id),
	
	PRIMARY KEY(usuario, forum)
);

-- views
-- forum + criador + validador
CREATE OR REPLACE VIEW private.foruns_com_autores AS
SELECT 
    f.*,
    u1.username AS criado_por_username,
    u2.username AS validado_por_username
FROM private.forum f
JOIN private.usuario u1 ON f.criado_por = u1.id
LEFT JOIN private.usuario u2 ON f.validado_por = u2.id;

-- procedures
-- USER INSERT PROCEDURE
-- USAGE -> CALL user_insert(<nome>, <nome de usuário>, <email>, <senha codificada>);
CREATE PROCEDURE public.user_insert (
	p_nome VARCHAR,
	p_username VARCHAR,
	p_email VARCHAR,
	p_senha_hash TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.usuario (nome, username, email, senha_hash)
	VALUES (p_nome, p_username, p_email, p_senha_hash);
END;
$$;

-- FORUM INSERT PROCEDURE
-- USAGE -> CALL forum_insert(<nome do forum>, <descrição do forum>, <id do criador do fórum>);
CREATE PROCEDURE public.forum_insert (
	p_titulo VARCHAR,
	p_descricao VARCHAR,
	p_criado_por INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.forum (titulo, descricao, criado_por)
	VALUES (p_titulo, p_descricao, p_criado_por);
END;
$$;

-- TAG INSERT PROCEDURE
-- USAGE -> CALL tag_insert(<nome da tag>, <id do criador da tag>);
CREATE PROCEDURE public.tag_insert (
	p_tag VARCHAR,
	p_criado_por INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.tag (tag, criado_por)
	VALUES (p_tag, p_criado_por);
END;
$$;

-- POSTAGEM INSERT PROCEDURE
-- USAGE -> CALL postagem_insert(<conteudo de texto>, <id do autor>, <id do fórum>, <arquivo (opcional)>);
CREATE PROCEDURE public.postagem_insert (
	OUT p_id INT,
	p_conteudo TEXT,
	p_criado_por INT,
	p_forum INT,
	p_arquivo BYTEA DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.conteudo (conteudo, criado_por)
	VALUES (p_conteudo, p_criado_por)
	RETURNING id INTO p_id;
	
	INSERT INTO private.postagem(id, forum, arquivo)
	VALUES (p_id, p_forum, p_arquivo);
END;
$$;

-- COMENTARIO INSERT PROCEDURE
-- USAGE -> CALL comentario_insert(<conteudo de texto>, <id do autor>, <id da postagem comentada/pai>, <id do comentário comentado>);
CREATE PROCEDURE public.comentario_insert (
	OUT p_id INT,
	p_conteudo TEXT,
	p_criado_por INT,
	p_postagem_pai INT,
	p_comentario_pai INT DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.conteudo (conteudo, criado_por)
	VALUES (p_conteudo, p_criado_por)
	RETURNING id INTO p_id;
	
	INSERT INTO private.comentario (id, postagem_pai, comentario_pai)
	VALUES (p_id, p_postagem_pai, p_comentario_pai);
END;
$$;

-- DENUNCIA p/ USUARIO INSERT PROCEDURE
-- USAGE -> CALL denuncia_usuario_insert(<motivador/tipo da denúncia>, <id do autor da denuncia>, <id do usuario que recebeu a denuncia>);
CREATE PROCEDURE public.denuncia_usuario_insert (
	OUT p_id INT,
	p_tipo VARCHAR,
	p_denunciante INT,
	p_usuario_denunciado INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.denuncia (tipo, denunciante)
	VALUES (p_tipo, p_denunciante)
	RETURNING id INTO p_id;
	
	INSERT INTO private.denuncia_usuario (id, usuario_denunciado)
	VALUES (p_id, p_usuario_denunciado);
END;
$$;

-- DENUNCIA p/ CONTEUDO INSERT PROCEDURE
-- USAGE -> CALL denuncia_conteudo_insert(<motivador/tipo da denúncia>, <id do autor da denuncia>, <id do conteudo que recebeu a denuncia>);
CREATE PROCEDURE public.denuncia_conteudo_insert(
	OUT p_id INT,
	p_tipo VARCHAR,
	p_denunciante INT,
	p_conteudo_denunciado INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.denuncia (tipo, denunciante)
	VALUES (p_tipo, p_denunciante)
	RETURNING id INTO p_id;
	
	INSERT INTO private.denuncia_conteudo (id, conteudo_denunciado)
	VALUES (p_id, p_conteudo_denunciado);
END;
$$;

-- AVALIAR POSTAGEM
-- USAGE -> CALL avaliar_postagem(<id do usuario que realiza a ação>, <id da postagem que recebe a avaliação>, <se 1, upvote, se -1, downvote>);
CREATE PROCEDURE public.avaliar_postagem (
	p_usuario INT,
	p_postagem INT,
	p_valor_avaliacao SMALLINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.avaliacao (usuario, postagem, valor_avaliacao)
	VALUES (p_usuario, p_postagem, p_valor_avaliacao);
END;
$$;

-- CLASSIFICAR POSTAGEM
-- USAGE -> CALL classificar_postagem(<id da postagem>, <id da tag>);
CREATE PROCEDURE public.classificar_postagem (
	p_postagem INT,
	p_tag INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.classificacao (postagem, tag)
	VALUES (p_postagem, p_tag);
END;
$$;

-- SEGUIR FORUM
-- USAGE -> CALL seguir_forum(<id do usuário>, <id do fórum>);
CREATE PROCEDURE public.seguir_forum (
	p_usuario INT,
	p_forum INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	INSERT INTO private.segue (usuario, forum)
	VALUES (p_usuario, p_forum);
END;
$$;


-- VALIDAR FÓRUM
-- USAGE -> CALL validar_forum(<id usuário que vai validar o fórum>, <fórum a ser validado>);
CREATE PROCEDURE public.validar_forum (
	p_validador INT,
	p_validado INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	UPDATE private.forum
	SET
		status = 'ACTIVE',
		validado_por = p_validador
	WHERE id = p_validado;
END;
$$;

-- FUNCTIONS
-- user select function
CREATE OR REPLACE FUNCTION public.listar_usuarios() 
RETURNS SETOF private.usuario
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	RETURN QUERY
	SELECT * FROM private.usuario
	ORDER BY id;
END;
$$;

-- search for a user through id
CREATE OR REPLACE FUNCTION public.buscar_usuario_por_id(
	p_id INT
)
RETURNS SETOF private.usuario
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	RETURN QUERY
	SELECT * FROM private.usuario
	WHERE id = p_id;
END;
$$;

-- search for a user/s through name
CREATE OR REPLACE FUNCTION public.buscar_usuario_pelo_nome(
	p_nome VARCHAR
)
RETURNS SETOF private.usuario
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	RETURN QUERY
	SELECT * FROM private.usuario
	WHERE nome = p_nome;
END;
$$;

-- foruns select function
CREATE OR REPLACE FUNCTION public.listar_foruns()
RETURNS SETOF private.forum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
	RETURN QUERY
	SELECT * FROM private.foruns_com_autores
	ORDER BY id;
END;
$$;
