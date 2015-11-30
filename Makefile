run:
	nodemon app.coffee

install:
	npm install

deploy:
	git push https://git.heroku.com/feedlist.git master
