# E-mail de convite do Portal do Cliente

O convite do portal usa `signInWithOtp` no ERP, então o Supabase envia o template de **Magic Link / OTP**. O HTML pronto fica em:

`supabase/templates/client_portal_magic_link.html`

## Configurar o remetente

Para o e-mail deixar de aparecer como Supabase, configure SMTP próprio no Supabase:

1. Acesse `Supabase Dashboard > Authentication > SMTP Settings`.
2. Habilite custom SMTP.
3. Configure um provedor como Resend, Brevo, SendGrid, Postmark ou AWS SES.
4. Use um remetente do domínio, por exemplo:
   - From name: `Granith`
   - From email: `portal@seudominio.com.br`
5. Valide SPF, DKIM e DMARC no DNS do domínio.

## Configurar o template

1. Acesse `Supabase Dashboard > Authentication > Emails`.
2. Abra o template `Magic Link`.
3. Cole o conteúdo de `supabase/templates/client_portal_magic_link.html`.
4. Use o assunto:

```text
Seu acesso ao Portal do Cliente Granith
```

## Observação

Se o fluxo do ERP for alterado no futuro para `inviteUserByEmail`, aplique o mesmo HTML no template `Invite user`.
