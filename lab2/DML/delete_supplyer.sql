DELETE FROM suppliers s
WHERE s.name = 'ООО "Поставка-Сервис"'
  AND NOT EXISTS (
    SELECT 1
    FROM incoming i
    WHERE i.supplier_id = s.id
  );
