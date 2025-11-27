# Mantém atributos de anotação
-keepattributes *Annotation*

# Evita avisos por anotações ausentes usadas por Tink / security-crypto
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.crypto.tink.**

# Opcionalmente mantém as classes de anotações em runtime (seguro)
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }

# Se quiser preservar tipos do Tink (mais conservador)
-keep class com.google.crypto.tink.** { *; }