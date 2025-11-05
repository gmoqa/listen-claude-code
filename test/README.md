# Testing del Plugin Listen-Interactive

Este directorio contiene herramientas para probar el wrapper `listen-interactive` **antes** de implementar el flag `--signal-mode` en `listen.py`.

## Archivos

### `mock-listen`
Script bash que simula el comportamiento de `listen --signal-mode`.

**Características:**
- Acepta los mismos argumentos que listen real: `-l`, `-m`, `--signal-mode`
- Responde correctamente a SIGUSR1
- Simula tiempo de grabación y procesamiento
- Retorna transcripciones de prueba basadas en la duración
- Logs detallados a stderr (suprimidos por el wrapper)

**Uso directo:**
```bash
# Iniciar en background
./mock-listen -l en -m base --signal-mode &
PID=$!

# Esperar unos segundos...
sleep 5

# Enviar SIGUSR1 para detener
kill -SIGUSR1 $PID

# Ver resultado
wait $PID
```

**Transcripciones generadas:**
- `< 3 segundos`: "Hello Claude"
- `3-6 segundos`: "Show me the Python files in this directory"
- `6-10 segundos`: "Create a function that calculates the factorial of a number"
- `> 10 segundos`: Mensaje largo de prueba
- Idioma español: "Muéstrame los archivos Python en este directorio"

### `test-wrapper.sh`
Script de test interactivo que prueba el flujo completo del wrapper con UI.

**Tests incluidos:**
1. **Test 1**: Funcionalidad básica (inglés, ~3 segundos)
2. **Test 2**: Idioma español (~6 segundos)
3. **Test 3**: SPACE rápido (< 3 segundos)

### `auto-test.sh`
Suite de tests automatizados sin interacción manual (ideal para CI/CD).

**Tests incluidos:**
1. **Test 1**: 2 segundos - inglés
2. **Test 2**: 5 segundos - español
3. **Test 3**: Stop inmediato (< 1 segundo)
4. **Test 4**: Modelo diferente (medium)

## Cómo Probar

### Opción 1: Test Rápido (Recomendado)

Verificación rápida de que SIGUSR1 funciona:

```bash
cd test
./quick-test.sh
```

### Opción 2: Test Automatizado Completo

Suite completa de tests sin interacción manual:

```bash
cd test
./auto-test.sh
```

Perfecto para:
- ✅ Verificar que el mock funciona
- ✅ CI/CD
- ✅ Test rápido antes de commits

### Opción 3: Test Interactivo con UI

Prueba la experiencia completa del usuario:

```bash
cd test
./test-wrapper.sh
```

Sigue las instrucciones en pantalla:
1. Presiona Enter para iniciar cada test
2. Espera a ver "● Listening [    ]"
3. Presiona SPACE cuando se indique
4. Verifica que aparezca "● Processing"
5. Confirma que recibes la transcripción

### Opción 2: Test Manual con Mock Global

Instala el mock temporalmente:

```bash
# Backup del listen real si existe
sudo mv /usr/local/bin/listen /usr/local/bin/listen.backup 2>/dev/null || true

# Instalar mock
sudo cp test/mock-listen /usr/local/bin/listen
sudo chmod +x /usr/local/bin/listen

# Probar el wrapper real
~/.local/bin/listen-interactive -l en -m base

# Restaurar listen real
sudo mv /usr/local/bin/listen.backup /usr/local/bin/listen 2>/dev/null || true
```

### Opción 3: Test desde Claude Code (Mock)

Temporalmente modifica el PATH para que use el mock:

```bash
# En una terminal
export PATH="/Users/gmoqa/Dev/listen-claude-code/claude-listen-plugin/test:$PATH"

# Iniciar Claude Code desde esta terminal
claude

# Dentro de Claude Code:
# /listen
```

## Qué Verificar

Durante las pruebas, confirma que:

### ✅ UI Visual
- [ ] Aparece "● Listening  [          ]" en rojo
- [ ] La barra anima entre vacía y llena
- [ ] El mensaje "Press SPACE to stop recording" es visible
- [ ] Aparece "● Processing" después de presionar SPACE

### ✅ Control Manual
- [ ] SPACE detiene la grabación inmediatamente
- [ ] No requiere presionar Enter
- [ ] Funciona en cualquier momento durante la grabación
- [ ] El terminal se restaura correctamente después

### ✅ SIGUSR1
- [ ] El mock recibe la señal correctamente
- [ ] El proceso termina limpiamente (no killed)
- [ ] La transcripción se captura correctamente
- [ ] No hay procesos zombie

### ✅ Integración
- [ ] La transcripción aparece en stdout
- [ ] No hay output basura mezclado
- [ ] El código de salida es 0
- [ ] El terminal queda en estado normal

## Troubleshooting

### "stty: stdin isn't a terminal"
Normal cuando se ejecuta desde Claude Code. El wrapper maneja esto correctamente con `2>/dev/null`.

### "mock-listen not found"
Verifica que estés en el directorio correcto y que el script tenga permisos de ejecución:
```bash
chmod +x test/mock-listen
```

### "Animation doesn't work"
Verifica que tu terminal soporte códigos ANSI. La mayoría de terminales modernos los soportan.

### "SPACE no funciona"
Asegúrate de que:
- No estés en un pipe (debe ser terminal interactiva)
- `stty` esté disponible en tu sistema
- No haya otros procesos capturando input

## Próximos Pasos

Una vez que todos los tests pasen:

1. ✅ El wrapper funciona correctamente
2. ✅ El control SPACE → SIGUSR1 funciona
3. ✅ La UI es clara y útil
4. 🚀 **Implementar `--signal-mode` en `listen.py`**

Consulta `../SIGNAL_MODE_SPEC.md` para la especificación completa de implementación.

## Debugging

Para ver los logs del mock:

```bash
# Modificar temporalmente el wrapper para no suprimir stderr:
# Cambiar: listen ... 2>/dev/null
# Por:     listen ... 2>&1

# Ejecutar
./listen-interactive -l en -m base
```

Verás logs como:
```
[mock-listen] Starting recording (language: en, model: base)
[mock-listen] PID: 12345
[mock-listen] Recording... 1s
[mock-listen] Recording... 2s
[mock-listen] SIGUSR1 received, stopping...
[mock-listen] Recording stopped after 3s
[mock-listen] Processing audio...
[mock-listen] Transcription complete
```

## Notas

- El mock es **solo para testing**, no reemplaza el listen real
- No requiere micrófono, Whisper, ni dependencias de audio
- Útil para CI/CD y testing automatizado
- Simula tiempos realistas de procesamiento
