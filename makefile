# Makefile for INC hybrid publications

## Issues:
# * why can't i make icmls before making markdowns ??

alldocx=$(wildcard docx/*.docx)
allmarkdown=$(filter-out md/book.md, $(shell ls md/*.md)) # TODO: add if, so that if no md is present no error: "ls: cannot access md/*.md: No such file or directory"
markdowns_compound=compound_src.md
epub=book.epub
icmls=$(wildcard icml/*.icml)


test: $(allmarkdown)
	echo "start" ; 
	echo $(allmarkdown) ; 
	echo "end" ;


folders:
	mkdir docx/ ; \
	mkdir md/ ; \
	mkdir md/imgs/ ; \
	mkdir icml/ ; \
	mkdir lib/ ; \
	mkdir scribus_html/ ;


markdowns: $(alldocx) # convert docx to md
	for i in $(alldocx) ; \
	do md=md/`basename $$i .docx`.md ; \
	echo "File" $$i $$md ; \
	pandoc $$i \
	       	--from=docx \
		--to=markdown \
	       	--atx-headers \
		--template=essay.md.template \
		-o $$md ; \
	./scripts/md_unique_footnotes.py $$md ; \
	done



icmls: $(allmarkdown)
	cd md && for i in $(allmarkdown) ; \
	do icml=icml/`basename $$i .md`.icml ; \
	pandoc ../$$i \
		--from=markdown \
		--to=icml \
		--self-contained \
		-o ../$$icml ; \
	done
	cd icml && sed -i -e 's/file\:imgs/file\:\.\.\/md\/imgs/g' *.icml ; # change links of images


scribus: $(allmarkdown)
	for i in $(allmarkdown) ; \
	do html=`basename $$i .md`.html ; \
	./scripts/md_stripmetada.py $$i > md/tmp.md ; \
	pandoc md/tmp.md \
		--from=markdown \
		--to=html5 \
		--template=scribus.html.template \
		-o scribus_html/$$html ; \
	done


book.md: clean $(allmarkdown)
	for i in $(allmarkdown) ; \
	do ./scripts/md_stripmetada.py $$i >> md/book.md ; \
	done


epub: clean $(allmarkdown) book.md epub/metadata.xml css/styles.epub.css epub/cover.jpg
	cd md && pandoc \
		--from markdown \
		--to epub3 \
		--self-contained \
		--epub-chapter-level=1 \
		--epub-stylesheet=../css/styles.epub.css \
		--epub-cover-image=../epub/cover.jpg \
		--epub-metadata=../epub/metadata.xml \
		--default-image-extension png \
		--toc-depth=6 \
		-o ../book.epub \
		--epub-embed-font=../css/Lato-Regular.ttf \
		--epub-embed-font=../css/Lato-Italic.ttf \
		--epub-embed-font=../css/Lato-Bold.ttf \
		--epub-embed-font=../css/Lato-BoldItalic.ttf \
		--epub-embed-font=../css/Lato-Light.ttf \
		book.md ; \
#include line, if you wanto embed font:
#		--epub-embed-font=../lib/UbuntuMono-B.ttf \

#TODO: automate font embedding (from CSS)

# use this to test the design without having to compile the EPUB
html: clean $(allmarkdown) book.md epub/metadata.xml css/styles.epub.css epub/cover.jpg
	cd html && pandoc \
		--from markdown \
		--to html \
		-s \
		-c ../css/styles.epub.css \
		-o book.html \
		../md/book.md ;
	cd html && sed -i -e 's/src="imgs/src="..\/md\/imgs/g' book.html ; # change links of images

# Created by Thomas Walskaar 2016 www.walska.com
floppy: clean $(allmarkdown) book.md epub/metadata.xml css/styles.epub.css epub/cover.jpg 
	cd txt && pandoc \
		--from markdown \
		--to plain \
		-s \
		-o book.txt \
		../md/book.md ; \
	rm /Volumes/FLOPPY/* ; \
	python ../scripts/floppynetwork.py book.txt /Volumes/FLOPPY # location of the floppy device

clean:  # remove outputs
	rm -f md/book.md  
	rm -f book.epub 
	rm -f *~ */*~  #emacs files

