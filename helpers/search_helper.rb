module SearchHelper
  def search_result_path(result)
    "/#{result._index}/#{result.id}"
  end
end
