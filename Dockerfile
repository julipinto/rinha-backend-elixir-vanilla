# --- ESTÁGIO 1: BUILD (AS builder) ---
# Usando a tag exata e compatível que você encontrou no Docker Hub
FROM hexpm/elixir:1.18.3-erlang-27.0.1-alpine-3.19.7 AS builder

# Define o ambiente como produção.
ENV MIX_ENV=prod

# Instala as ferramentas de build para o Alpine
RUN apk add --no-cache build-base git

# Cria o diretório da aplicação
WORKDIR /app

# Instala as ferramentas do Elixir
RUN mix local.hex --force && mix local.rebar --force

# Copia os arquivos de dependência primeiro
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copia o resto do código da aplicação
COPY . .

# Compila a aplicação e cria a release executável.
RUN mix release rinha_vanilla

# --- ESTÁGIO 2: RUNTIME (final) ---
# Usamos a mesma versão base do Alpine para consistência
FROM alpine:3.19 AS runner

# Define o ambiente como produção.
ENV MIX_ENV=prod

# Instala as dependências de runtime mínimas
RUN apk add --no-cache openssl ncurses-libs

# (Melhoria de Segurança) Cria um usuário não-root para rodar a aplicação.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
USER appuser

# Copia a release compilada do estágio de "build"
COPY --from=builder /app/_build/prod/rel/rinha_vanilla .

# A porta interna que sua aplicação usa.
EXPOSE 8080

# O comando para iniciar a aplicação.
CMD ["bin/rinha_vanilla", "foreground"]