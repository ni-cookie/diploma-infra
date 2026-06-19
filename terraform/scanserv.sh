#!/bin/bash

while true; do
  echo "Попытка создания инстанса: $(date)"
  
  # Запускаем терраформ. Если он отработает без ошибок (код 0), цикл прервется.
  if terraform apply -auto-approve; then
    echo "Ура! Сервер успешно создан."
    break
  else
    echo "Не удалось создать. Ждем 5 минут..."
    sleep 300
  fi
done