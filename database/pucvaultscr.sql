-- create
CREATE TABLE usuario(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	nome VARCHAR(75) NOT NULL,
	username VARCHAR(20) NOT NULL,
	email VARCHAR(50) NOT NULL,
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
		CHECK (status IN ('PUBLISHED', 'FIXED', 'DELETED'))	,
	
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
	postagem_pai INT REFERENCES postagem(id) NOT NULL,
	comentario_pai INT REFERENCES comentario(id)
);

-- DENUNCIA -> GENERALIZADO
CREATE TABLE denuncia(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tipo VARCHAR(30) NOT NULL,
	descricao VARCHAR(100),
	data_criacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	
	denunciante INT REFERENCES usuario(id)
);

-- DENUNCIA -> DENUNCIA PARA USUARIO ESPECIALIZADO
CREATE TABLE denuncia_usuario(
	id INT PRIMARY KEY REFERENCES denuncia(id),
	usuario_denunciado INT REFERENCES usuario(id)
);

-- DENUNCIA -> DENUNCIA PARA CONTEUDO ESPECIALIZADO
CREATE TABLE denuncia_conteudo(
	id INT PRIMARY KEY REFERENCES denuncia(id),
	conteudo_denunciado INT REFERENCES conteudo(id)
);

--TABELAS AUXILIARES
-- AVALIAÇÃO POSTAGEM (N) <-> USUARIO (N)
CREATE TABLE avaliacao(
	usuario INT REFERENCES usuario(id),
	postagem INT REFERENCES postagem(id),
	valor_avaliacao SMALLINT NOT NULL,

	CONSTRAINT valor_avaliacao
		CHECK (valor_avaliacao IN (1,-1)),

	PRIMARY KEY(usuario, postagem)
);

-- CLASSIFICAÇÃO POSTAGEM (N) <-> TAGS (N)
CREATE TABLE classificacao(
	postagem INT REFERENCES postagem(id),
	tag INT REFERENCES tag(id),
	
	PRIMARY KEY(postagem, tag)
);

-- SEGUE USUARIO (N) <-> FÓRUM (N)
CREATE TABLE segue(
	usuario INT REFERENCES usuario(id),
	forum INT REFERENCES forum(id),
	
	PRIMARY KEY(usuario, forum)
);