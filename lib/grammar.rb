module ZQL
  class OrderBy; end
  class GroupBy; end

  module Grammar
    MULTI_WORD_FUNCTIONS = {
      'order by' => OrderBy,
      'group by' => GroupBy
    }
  end
end
