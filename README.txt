Pixel Guardians (Flutter)
1) flutter create --platforms=android,ios,windows,macos,linux,web .   (в этой папке, файлы lib/ и pubspec не перезаписываются)
2) flutter run
Управление: WASD/стрелки, пробел - атака, 1/2/3 - герой. Телефон: палец по левой половине - движение, кнопка АТАКА.
Спрайты генерируются кодом; звуки - из WAV, генерируемых в коде; сохранение - shared_preferences. Сначала: flutter pub get.

Сборка APK через GitHub Actions:
1) Создай репозиторий на GitHub и залей содержимое этой папки (git init, git add ., git commit, git push в ветку main).
2) Вкладка Actions -> "Build APK" запускается сама при push (или вручную: Run workflow).
3) Когда сборка завершится, открой запуск и скачай артефакт pixel-guardians-apk (внутри app-release.apk).
4) Установи APK на телефон (разреши установку из неизвестных источников).
Папка android/ создаётся в CI командой flutter create, хранить её в репозитории не нужно.
