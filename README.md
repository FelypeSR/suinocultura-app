# gspr

gerenciador

## ⚠️ Configuração necessária para Login com Google

Para que o login com Google funcione no Android, é preciso adicionar a **SHA-1** do certificado de debug ao Firebase Console:

1. Gere a SHA-1 rodando no terminal:
   ```
   cd android && ./gradlew signingReport
   ```
2. Copie o valor da linha `SHA1:` que aparecer em **Variant: debug**
3. Acesse o [Firebase Console](https://console.firebase.google.com/)
4. Vá em **Configurações do projeto → Seus apps → (seu app Android)**
5. Clique em **Adicionar impressão digital** e cole a SHA-1
6. Baixe o novo `google-services.json` e substitua o arquivo em `android/app/`

Sem esse passo, o Google rejeitará a autenticação e o login não funcionará.

---

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
