---
name: run-gspr
description: Run, build, and deploy the GSPR Flutter app to a connected Android device via USB debugging. Use when asked to run, start, build, test, or deploy the app.
---

App Flutter de suinocultura com Firebase. Roda em Android via USB (ADB) ou Chrome/Windows como fallback web.

## Dispositivo principal

Samsung Galaxy A15 5G (SM A155M) — conectado via USB debug.  
Device ID atual: `RQ8X3040TNH` (pode mudar se reconectar).

Para listar o ID atual:
```
flutter devices
```

## Pré-requisitos

- Flutter SDK no PATH (`flutter doctor` deve mostrar tudo verde)
- Android SDK instalado (o build instala plataformas faltantes automaticamente)
- Depuração USB ativada no celular + autorizar o PC quando solicitado
- **C: deve ter espaço livre** — o build grava em `build/` dentro do projeto. Se C: estiver cheio, mover o projeto para outra partição ou redirecionar `GRADLE_USER_HOME`.

## Rodar no Android (caminho principal)

```
flutter run -d RQ8X3040TNH
```

Primeira build leva ~3-5 min (Gradle baixa dependências). Builds subsequentes são rápidas.

Após subir, tirar screenshot via ADB:
```
adb -s RQ8X3040TNH shell screencap -p /sdcard/screen.png
adb -s RQ8X3040TNH pull /sdcard/screen.png screen.png
```

## Rodar no Chrome (fallback rápido)

```
flutter run -d chrome
```

Útil para testar widgets sem precisar do celular conectado.

## Tela inicial

`main.dart` aponta para `WidgetTestScreen` (telateste.dart) por padrão.  
Para testar outra tela, trocar `home:` em `main.dart` temporariamente.

## Gotchas

**Plugin google-services duplicado** — `settings.gradle.kts` (gerado pelo FlutterFire) já declara `com.google.gms.google-services:4.3.15`. Se `build.gradle.kts` declarar novamente com versão diferente, o build falha com:
```
The request for this plugin could not be satisfied because the plugin is already on the classpath with a different version
```
**Fix:** remover o bloco `plugins { id("com.google.gms.google-services") ... }` do `build.gradle.kts`. Já aplicado.

**Disco cheio no Windows** — Gradle e Flutter gravam em `C:\Users\...\` por padrão. Se C: não tiver espaço, definir antes de rodar:
```
set GRADLE_USER_HOME=D:\gradle-cache
flutter run -d RQ8X3040TNH
```
No Linux esse problema não ocorre.

**Android SDK Platform auto-instalado** — na primeira build, o Gradle pode baixar e instalar o Android SDK Platform necessário automaticamente. Normal, não é erro.

## Troubleshooting

| Erro | Fix |
|---|---|
| `device not found` | `flutter devices` para ver ID atual; verificar cabo e autorização USB |
| `Espaço insuficiente no disco` | Liberar C: ou usar `GRADLE_USER_HOME` em outra partição |
| `plugin already on classpath` | Remover bloco `plugins {}` do `android/build.gradle.kts` |
| `firebase_options.dart` não encontrado | Rodar `flutterfire configure` para regenerar |