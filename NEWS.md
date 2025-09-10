# cowfootR 0.1.0

* Initial CRAN submission.

pkgdown::build_site()
# 1) Instalar pkgdown si no lo tenés
install.packages("pkgdown")

# 2) Generar el sitio localmente
pkgdown::build_site()

# 3) Publicar en GitHub Pages
pkgdown::deploy_to_branch()   # crea/actualiza la rama gh-pages

