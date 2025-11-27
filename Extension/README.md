# Universal Browser - Extensão do Navegador

## 🚀 Instalação e Teste Local

### Pré-requisitos
- Google Chrome, Microsoft Edge, ou navegador baseado em Chromium
- Modo desenvolvedor habilitado nas extensões

### Como instalar para teste

1. **Abra o Chrome/Edge** e vá para:
   - Chrome: `chrome://extensions/`
   - Edge: `edge://extensions/`

2. **Ative o Modo Desenvolvedor** (toggle no canto superior direito)

3. **Clique em "Carregar sem compactação"** ou "Load unpacked"

4. **Selecione a pasta** `C:\UniversalBrowser\Extension`

5. **A extensão será carregada** e aparecerá na lista

### Como usar

1. **Clique no ícone** da extensão na barra de ferramentas
2. **Adicione perfis** dos sites que deseja monitorar
3. **Configure o intervalo** de monitoramento (padrão: 30 segundos)
4. **Ative o monitoramento** e navegue normalmente

## 📋 Funcionalidades

### ✅ Implementadas
- ✅ Sistema de perfis personalizado
- ✅ Monitoramento automático de sites
- ✅ Recuperação automática de abas fechadas
- ✅ Interface popup completa
- ✅ Perfis pré-configurados (iFood, WhatsApp, Gmail, Office 365)
- ✅ Estatísticas em tempo real
- ✅ Notificações do sistema
- ✅ Detecção de conectividade
- ✅ Indicador visual nas páginas monitoradas
- ✅ Exportar/importar configurações
- ✅ Modo debug com logs detalhados

### 🎯 Sites Pré-configurados
- **iFood Gestor**: `gestordepedidos.ifood.com.br`
- **WhatsApp Web**: `web.whatsapp.com`
- **Gmail**: `mail.google.com`
- **Office 365**: `portal.office.com`

## 🔧 Desenvolvimento

### Estrutura de Arquivos
```
Extension/
├── manifest.json          # Configuração da extensão
├── popup.html             # Interface principal
├── popup.css              # Estilos da interface
├── popup.js               # Lógica da interface
├── background.js          # Script de background
├── content.js             # Script de conteúdo
├── icons/                 # Ícones da extensão
│   ├── icon16.png
│   ├── icon32.png
│   ├── icon48.png
│   └── icon128.png
└── README.md              # Este arquivo
```

### Permissões Necessárias
- `tabs`: Gerenciar abas
- `storage`: Salvar configurações
- `alarms`: Agendamento de monitoramento
- `notifications`: Notificações do sistema
- `scripting`: Verificar responsividade das páginas
- `host_permissions`: Acesso a todos os sites

### Debugging
1. Abra `chrome://extensions/`
2. Clique em "Detalhes" na extensão
3. Clique em "background.html" para ver logs
4. Use F12 para debuggar popup e content scripts

## 📦 Distribuição

### Preparar para Chrome Web Store

1. **Criar arquivo ZIP**:
   ```powershell
   Compress-Archive -Path "C:\UniversalBrowser\Extension\*" -DestinationPath "universal-browser-extension.zip"
   ```

2. **Verificar arquivos obrigatórios**:
   - ✅ manifest.json
   - ✅ popup.html, popup.css, popup.js
   - ✅ background.js
   - ✅ content.js
   - ✅ Ícones (16, 32, 48, 128px)

3. **Informações para a Store**:
   - **Nome**: Universal Browser - Site Monitor
   - **Descrição**: Monitore e mantenha seus sites favoritos sempre abertos
   - **Categoria**: Productivity
   - **Idiomas**: Português (Brasil), English
   - **Privacidade**: Não coleta dados pessoais

### Screenshots Necessários
- Interface principal (popup)
- Configuração de perfis
- Monitoramento em ação
- Estatísticas

### Política de Privacidade
A extensão:
- ✅ Armazena dados localmente no navegador
- ✅ Não envia dados para servidores externos
- ✅ Não coleta informações pessoais
- ✅ Acessa apenas sites configurados pelo usuário

## 🔄 Atualizações

### Versão 1.0.0 (Atual)
- Lançamento inicial
- Sistema completo de monitoramento
- Interface moderna
- Perfis pré-configurados

### Próximas Versões
- **v1.1.0**: Melhorias na interface, mais perfis
- **v1.2.0**: Sincronização entre dispositivos
- **v1.3.0**: API para integração externa

## 🐛 Resolução de Problemas

### Extensão não carrega
- Verifique se está em modo desenvolvedor
- Recarregue a extensão em `chrome://extensions/`
- Verifique erros no console

### Monitoramento não funciona
- Verifique se o perfil está ativo
- Confirme as permissões da extensão
- Teste com outro site

### Sites não recuperam
- Verifique a conectividade
- Aumente o intervalo de monitoramento
- Desative bloqueadores de popup

## 📞 Suporte

- **Site**: https://universalbrowser.vercel.app
- **Documentação**: https://universalbrowser.vercel.app/documentation
- **GitHub**: https://github.com/juliocamposmachado/UniversalBrowser

## 📄 Licença

MIT License - Uso livre para fins comerciais e pessoais.

---

**Universal Browser Extension v1.0.0**  
*Nunca mais perca trabalho por sites que fecham inesperadamente!* 🛡️