# ---------- Build Stage ----------
FROM {{BASE_IMAGE}} as builder
WORKDIR /build
COPY . .
RUN {{BUILD_CMD}}

# ---------- Runtime Stage ----------
FROM {{BASE_IMAGE}}
WORKDIR /app
COPY --from=builder /build /app
USER 1001
EXPOSE {{PORT}}

# ---------- Runtime Command ----------
CMD ["{{RUN_CMD}}"]
