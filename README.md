# README

### Используемые имена кук

* s - сессия, выставляется рельсами на все поддомены проекта
* l - логин пользователя на сайте, используется при авторизации, устанавливается только на корневой сайт
* lm - то же самое что и l, только для мобильной версии


### Забронированные поля в сессии

* :u - id текущего пользователя
* :ip — ip адрес текущей сессии
* :sig — подпись для текущего id пользователя
* :r - строка редиректа, в основном используется при авторизации для перенаправления на страницу с которой пришел пользватель
* 'flash' — используется RoR
* :_csrf_token — используется RoR
* :session_id — используется RoR


### Используемые поля в users.settings

* ng - not grateful, int(0,1) (premium#grateful)
* ln - linked accounts, array\[user_id, user_id, …\] (premium#accounts)
* last_kind
* last_rating
* last_personalized_keys


### Используемые ключи в Redis

* u:<id>:q — персональная очередь постов пользователя
* n:<id> — соседи по постам
* q:<id> — личная очередь пользователя (Моё)
* e:ping — pub/sub в который попадают новые записи
* e:queue:<key> — какой-либо из эфиров (прямой, лучшее и т.п.)
* chat:... — используется для чата
* ping — для уведомления яндекса о новых постах


### Annotate

	$ bundle exec annotate -p before -m -i -s --exclude tests,fixtures

 
### Resque Web Interface

	$ RAILS_ENV=production RACK_ENV=production RAILS_ROOT=`pwd` bundle exec resque-web -p 8282 tmp/resque-web-config.rb

