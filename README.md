# LSL_translator

The LSL Translator uses the https://frengly.com/api <br>
with a simple notecard it could be configured with the following simple settings:

From:de<br>
To:en<br>
Account:yourname@mail.com<br>
Password:yourpassword<br>

Supported language codes are:<br>
ar, bg, zhCN, zhTW, hr, cs, da, nl, en, et, tl, fi, fr, de, el, iw, hi, hu, is, id, ga,<br>
it, ja, ko, la, lv, lt, mk, mt, no, fa, pl, pt, ro, ru, sr, sk, si, es, sv, th, tr, vi

The translator is free but you shold use a registerd account.<br>
You can register a new account under: https://frengly.com/translate<br>

your accountname and password should be used in the notecard which has to be in the same object with the scripts.<br>

The name of the notecard must be: TranslatorConfigNC<br>

Initial ojbect setting in SL:<br>
1. create a new translator object<br>
2. put the scripts and the NC into the object<br>
3. attach the object and start translation<br>

Debug settings:<br>
At the moment debug settings are activated. To deactivate them, simple set the constant debug_output in the script IOHandler to FALSE.<br>




