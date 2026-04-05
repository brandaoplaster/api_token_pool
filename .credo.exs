%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ~w{config lib test},
        excluded: [
          ~r"/_build/",
          ~r"/deps/"
        ]
      },
      plugins: [],
      requires: [],
      strict: true,
      color: true,
      parse_timeout: 5000,
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.MaxLineLength, max_length: 100},
          {Credo.Check.Consistency.TabsOrSpaces},
          {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 100},
          {Credo.Check.Design.TagTODO, exit_status: 2},
          {Credo.Check.Refactor.MapInto, false},
          {Credo.Check.Warning.LazyLogging, false},
          {Credo.Check.Readability.SinglePipe, []},
          {Credo.Check.Design.AliasUsage,
           [priority: :low, if_nested_deeper_than: 4, if_called_more_often_than: 0]},
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []}
        ]
      }
    }
  ]
}
