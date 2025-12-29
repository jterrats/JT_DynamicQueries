# Preview Local de GitHub Pages

## Requisitos Previos

1. **Ruby** (ya instalado: `ruby --version`)
2. **Bundler** (ya instalado: `bundle --version`)
3. **Jekyll** (se instalará con bundle)

## Instalación

```bash
# Instalar dependencias de Jekyll
npm run docs:install
# O manualmente:
bundle install
```

## Ejecutar Preview Local

```bash
# Opción 1: Usar script npm (recomendado)
npm run docs:serve

# Opción 2: Manualmente
cd docs
bundle exec jekyll serve --baseurl ''
```

El sitio estará disponible en: **http://localhost:4000**

## Notas

- El flag `--baseurl ''` es necesario para que los links funcionen correctamente en local
- Los cambios en archivos se reflejan automáticamente (hot reload)
- Presiona `Ctrl+C` para detener el servidor

## Troubleshooting

Si tienes problemas con permisos de Ruby/Bundler:
```bash
# Usar bundle con --path local
bundle install --path vendor/bundle
bundle exec jekyll serve --baseurl ''
```
