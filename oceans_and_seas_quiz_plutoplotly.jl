### A Pluto.jl notebook ###
# v0.19.9

#> [frontmatter]
#> title = "ocean_and_sea_locator"
#> date = "2022-06-15"
#> description = "Find out where the ocean/sea is located"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 2c5477fc-e794-11ec-17ea-7fc681f9a79b
begin
	using OceanBasins
	using PlutoPlotly
	using PlutoUI
	using GeoDatasets
	# using Proj # Not sure how to use this with Plots.jl
	using ColorSchemes
end

# ╔═╡ ed82ef42-217d-4ca7-92a4-523fb7203338
md"# The ocean/sea guessing game in Pluto"

# ╔═╡ 1dd172af-436c-4331-8238-f6caabb16c0d
md"Show the solution $(@bind give_up CheckBox(default=false))"

# ╔═╡ 4958000b-e192-4242-9143-42f7a13d51a1
attrmerge(d::PlotlyBase.PlotlyAttribute...) = reduce(merge, d; init = attr())

# ╔═╡ dc4a32d3-3c92-493f-8b3d-ea21eba196ce
md"## Packages and plots"

# ╔═╡ 7a6b2d0f-1038-4e57-8b3c-2831787dcc3d
TableOfContents()

# ╔═╡ 7f68b4d5-f2d3-4563-9942-1bbc3ba97f2b
function ocean_coords(ocn)
	ll_vec = map(ocn.polygon) do p
		(p.lat, p.lon)
	end
	(;lat = first.(ll_vec), lon = last.(ll_vec))
end

# ╔═╡ cd068126-b9f3-4b0a-8431-fa22344fe6b5
ptjs(x) = Main.PlutoRunner.publish_to_js(x)

# ╔═╡ 9f256c6c-6d82-48b0-b91f-ddd664f279a5
function change_visibility(flag)
	update = attr(
		data = attr(
			trace0 = attr(
				visible = flag
			)
		)
	)
end

# ╔═╡ f417361a-70ae-4070-ae08-9e3491388d68
land_color, water_color, wrong_color, right_color = ColorSchemes.seaborn_colorblind[[8, 1, 4, 3]]

# ╔═╡ f562a079-ee48-434a-8c93-7f7fe149a553
md"""
!!! note
	If you never used OceanBasins.jl, the download in the cell below will fail as it will wait for a y/n prompt on the console, which you can't provide from Pluto.\
	Call the function from the REPL the first time in order to permit the database download
"""

# ╔═╡ 1c346ac8-2842-4454-a22c-da4842ce29fa
oceans_select_list = [ocn=>ocn.name for ocn in oceanpolygons()]

# ╔═╡ 75816aaa-59be-43fa-b6d5-6be142634cf8
@bind ocean_selected Select(oceans_select_list)

# ╔═╡ 479cd750-07e0-462e-8379-64f095c9c9b7
ocean_selected

# ╔═╡ 44762d59-d3ea-4144-b4c5-3b9db3bf08a6
(-10, -30) ∈ ocean_selected

# ╔═╡ 35897111-72c9-4479-a481-87cf2cc0cdea
oceans_that_contain(x) = [ocn for (ocn, str) in oceans_select_list if x ∈ ocn]

# ╔═╡ a952f635-5eea-4b67-9ff9-46a7a25de9dc
oceans_that_contain((-70, -50))

# ╔═╡ 00587f0c-ef2c-4133-b2c8-a7019076d99d
md"## Extras for user interface"

# ╔═╡ aa87d1a0-5378-4fd9-9476-f9af246aa549
selected_ocean_ref = Ref{OceanOrSea}(oceans_select_list[1][1])

# ╔═╡ ebb7b2a5-2660-46ce-8a9d-6e935b34371c
selected_ocean_ref[]

# ╔═╡ 912b2ae6-27fc-42d8-8650-c1248536aeb1
ocean_coords(selected_ocean_ref[])

# ╔═╡ d85676a2-ea69-4532-921a-b61c922a99f5
function change_ocean(ocn)
	selected_ocean_ref[] = ocn
	coords = ocean_coords(ocn)
	data = attr(trace0 = attr(;
		coords...
	),
		trace1 = attr(;lat = [NaN, NaN], lon = [NaN, NaN]),
		trace2 = attr(;lat = [NaN, NaN], lon = [NaN, NaN])
	)
	layout = attr(
		title = attr(
			text = "Where is the $(ocn.name)?"
		),
	)
	update = attr(;data, layout)
end

# ╔═╡ 65e3b758-0f59-4447-82d4-0c28126199c9
give_up_ref = Ref{Bool}(false)

# ╔═╡ 4b08d7ff-e31e-467a-8469-05ab480ac10b
let
	ocean_selected
	# We change selection so we restart the color
	change_visibility(give_up_ref[])
end

# ╔═╡ 5525e152-f81a-4eae-81bf-224303583883
click_count_ref = Ref(0)

# ╔═╡ c477bd21-94b8-435d-8aa0-7bd4c75cf231
function set_counter(num)
	click_count_ref[] = num
	layout = attr(
		click_count = num
	)
	attr(;layout)
end

# ╔═╡ f44739a6-a46f-48af-b4e8-978f45895b35
function rgb2str(c::ColorSchemes.ColorTypes.RGB) 
	"#$(ColorSchemes.Colors.hex(c))"
end

# ╔═╡ 3e96a1f7-1e42-488b-bf50-89c76dd9a918
const var"@htl" = PlutoPlotly.var"@htl"

# ╔═╡ 26789f57-0cba-4f3e-9f95-9a005ee032ab
function apply_update(update::PlotlyBase.PlotlyAttribute)
	data = get(update, :data, Dict())
	layout = get(update, :layout, Dict())
	@htl """
		<script>
			const PLOT = document.querySelector('div.js-plotly-plot')
			const plot_obj = {
				data: PLOT.data,
				layout: PLOT.layout
			}

			function isArrayOrTypedArray(x) {
			    return Boolean(x && (typeof x === 'object') && (Array.isArray(x) || (ArrayBuffer.isView(x) && !(x instanceof DataView))));
			}
			const customizer = (dv, sv, key) => {
				if (isArrayOrTypedArray(dv) && isArrayOrTypedArray(sv)) {
					return sv
				} else {
			    	return undefined
				}
			}
			for (const [key, val] of Object.entries($(ptjs(data)))) {
				let idx = key.substr(5)
				_.mergeWith(plot_obj.data[idx], val, customizer)
			}
	
			_.merge(plot_obj.layout, $(ptjs(layout)))

			//console.log(plot_obj)
			Plotly.react(PLOT, plot_obj)
		</script>
	"""
end

# ╔═╡ 0bc57854-b2a2-4cb5-9155-3100c8aae411
let
	give_up_ref[] = give_up
	change_visibility(give_up) |> apply_update
end

# ╔═╡ 90cc011b-cf18-4121-84d1-46ffcb5fdcc1
function color_to_components(c::ColorSchemes.Colors.Colorant)
	uint = ColorSchemes.Colors._to_uint32(c)
	b = uint % UInt8
	g = (uint >> 8) % UInt8
	r = (uint >> 16) % UInt8
	a = ((uint >> 24) % UInt8) / 0xff
	r,g,b,a
end

# ╔═╡ f1ff33a1-b4de-4a07-9a94-28c874d2ab07
c2s(s::String) = s

# ╔═╡ 343df1af-99ef-47fa-a5c7-46278d27cf7f
function c2s(c::ColorSchemes.Colors.Color)
	r,g,b,a = color_to_components(c)
	"rgb($r,$g,$b)"
end

# ╔═╡ f4d2e8c2-7717-4181-aaf7-602bd1b7a5de
function c2s(c::ColorSchemes.Colors.TransparentColor)
	r,g,b,opacity = color_to_components(c)
	a = round(opacity;digits=2)
	"rgba($r,$g,$b,$a)"
end

# ╔═╡ f776dabd-fb61-494f-a33d-14379458ea2e
function c2s(c::ColorSchemes.Colors.Colorant, opacity::AbstractFloat)
	r,g,b,_ = color_to_components(c)
	a = round(opacity;digits=2)
	"rgba($r,$g,$b,$a)"
end

# ╔═╡ 7a5968a0-0ba3-44fc-9f4c-d25b5f528d2b
let
	asd = Dict(:fillcolor => c2s(water_color))
	@htl """
	<script>
		console.log($(ptjs(asd)))
	</script>
	"""
end

# ╔═╡ 44181dab-060b-4b5b-85f8-cf0245bdfa89
function change_color(c)
	data = if c isa String
		attr()
	else
		attr(trace0 = attr(fillcolor = c2s(c,0.4)))
	end
	layout = attr(paper_bgcolor = c2s(c))
	attr(; data, layout)
end

# ╔═╡ 1d377b9e-e7af-40c7-a32d-8715615ff80c
let
	click_count_ref[] = 0 # We reset the counter
	global ocean_selected_triggered = true 
	attrmerge(
		change_ocean(ocean_selected),
		change_color(""),
		change_visibility(give_up_ref[])
	) |> apply_update
end

# ╔═╡ 3f17298c-49b3-4937-a3d0-ea2c1b1fb4da
function plot_ocean()
	crosshair = [
		# This contains the horizontal lat line and vertical lon line to mark the previous clicked point
		scattergeo(;
			mode = "lines",
			line = attr(
				color = "black",
				width = .7,
			),
			showlegend = false,
			hoverinfo = "skip",
		),		
		scattergeo(;
			mode = "lines",
			line = attr(
				color = "black",
				width = .7,
			),
			showlegend = false,
			hoverinfo = "skip",
		)
	]
	ocean_shape = scattergeo(;
		ocean_coords(selected_ocean_ref[])...,
		fill = "toself",
		fillcolor = c2s(right_color,.4),
		mode = "lines",
		line = attr(
			color = "black",
			width = .5,
		),
		showlegend = false,
		# hoverinfo = "skip",
	)
	p = plot([ocean_shape, crosshair...], Layout(
		margin = attr(
			l = 20,
			b = 20,
			t = 20,
			r = 20,
		),
		paper_bgcolor = "",
		geo = attr(
			landcolor = c2s(land_color),
			showland = true,
			oceancolor = c2s(water_color),
			showocean = true,
			# lakecolor = c2s(water_color),
			# showlake = true,
			lataxis = attr(
				showgrid = true,
				gridcolor = "rgba(0,0,0,.2)",
				dtick = 30,
			),
			lonaxis = attr(
				showgrid = true,
				gridcolor = "rgba(0,0,0,.2)",
				dtick = 50,
				tick0 = 20,
			),
		),
		title = attr(
			text = "Where is the $(selected_ocean_ref[].name)?",
			y = 1,
			yanchor = "top",
			yref = "container",
			pad = attr(
				t = 10
			)
		),
		template = "none",
		height = 380,
	))
	push_script!(p,"
		let drag = false
		let mdown = false
		const {format} = await import('https://cdn.skypack.dev/d3-format@3');
		const f2f = format('.2f')
	")	
	push_script!(p,"
		const modlon = x => {
			if (x > 180) {
				return -180 + (x % 180)
			} else if (x < -180) {
				return 180 + (x % 180)
			} else {
				return x
			}
		}
		const latlon_text = llvec => { 
			let lat = llvec[0]
			let lon = llvec[1]
			return (lat > 90 || lat < -90) ? '' : `Lat: \${f2f(lat)}, Lon: \${f2f(lon)}`
		}
	")
	push_script!(p,"
	const extract_coords = (e) => {
		const svgrect = e.target.getBoundingClientRect()
		const f = [
			(e.clientX - svgrect.left) / svgrect.width - .5, 
			(e.clientY - svgrect.top) / svgrect.height - .5
		]
		const geo = PLOT._fullLayout.geo
		const center = geo.center
		const scale = geo.projection.scale
		const latrange = geo.lataxis.range
		const dlat = (latrange[0] - latrange[1])/scale
		const lat0 = center.lat
		const lonrange = geo.lonaxis.range
		const dlon = (lonrange[1] - lonrange[0])/scale
		const lon0 = center.lon
		let mouselat = f[1] * dlat + lat0
		let mouselon = modlon(f[0] * dlon + lon0)
		return [mouselat, mouselon]
	}
	")
	push_script!(p,"
	const plot_coords = (ll) => {
		let update = {
			annotations: [{
			xref: 'paper',
			yref: 'paper',
			x: 0.5,
			xanchor: 'center',
			y: 0,
			yanchor: 'top',
			text: latlon_text(ll),
			showarrow: false
		  }, 
		]}
		Plotly.relayout(PLOT, update)
	}
	")
	add_js_listener!(p, "mousedown", "() => {drag = false; mdown = true}")
	add_js_listener!(p, "mousemove", "() => drag = true")
	add_js_listener!(p, "mouseup", "(e) => {
		mdown = false
		if (e.target.tagName !== 'rect' || drag) {
			return
		} else {
			let ll = extract_coords(e)
			PLOT.value = ll
			PLOT.dispatchEvent(new CustomEvent('input'))
			let lat = ll[0]
			let lon = ll[1]
			let lon_vec = _.range(-180,180,.5)
			const data_update = {
				lat: [lon_vec.map(() => lat), [-90, 90]],
				lon: [lon_vec, [lon, lon]]
			}
			Plotly.restyle(PLOT, data_update, [1,2])
		}
	}")
	add_js_listener!(p, "mousemove", "(e) => {
		if (e.target.classList.contains('js-plotly-plot') || mdown) {
			return
		} else {
			let ll = extract_coords(e)
			plot_coords(ll)
		}
	}")

end

# ╔═╡ 706c90e3-0900-46c1-965a-44435fcd4cea
@bind x0 plot_ocean()

# ╔═╡ 10b3aead-310e-4fb9-9816-6bafec58e097
x0

# ╔═╡ 552dd710-db8c-4f13-aceb-994966e1d5a6
x0 ∈ selected_ocean_ref[]

# ╔═╡ 03768224-ddef-4c0d-8e23-c5ccdba119a9
let
	global click_triggered = true
	correct = x0 ∈ selected_ocean_ref[]
	click_count_ref[] += 1
	if correct
		attrmerge(
			change_color(right_color),
			change_visibility(true),
		) |> apply_update
	else
		attrmerge(
			change_color(wrong_color),
			change_visibility(give_up_ref[]),
		) |> apply_update
	end
end

# ╔═╡ 5428392e-0d61-4a56-bbdf-64b1572308f8
let
	ocean_selected_triggered
	click_triggered
	nclick = click_count_ref[]
	max_click = 10
	if nclick < max_click
		str = "$nclick/$max_click"
	md"Attempts: $str"
	else
		md"You have reached the maximum number of attempts!\
		Change Sea to restart or flag the checkmark above to show the solution"
	end
end

# ╔═╡ 9aa47be6-08b7-43bc-8a5f-20acc081c121
PlutoPlotly._default_script_contents

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ColorSchemes = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
GeoDatasets = "ddc7317b-88db-5cb5-a849-8449e5df04f9"
OceanBasins = "d1bb7020-b2be-4340-9d18-d24ca645bddb"
PlutoPlotly = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
ColorSchemes = "~3.18.0"
GeoDatasets = "~0.1.6"
OceanBasins = "~0.1.7"
PlutoPlotly = "~0.3.4"
PlutoUI = "~0.7.39"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.1"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BinaryProvider]]
deps = ["Libdl", "Logging", "SHA"]
git-tree-sha1 = "ecdec412a9abc8db54c0efc5548c64dfce072058"
uuid = "b99e7846-7c00-51b0-8f62-c81ae34c0232"
version = "0.5.10"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9489214b993cd42d17f44c36e359bf6a7c919abf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "7297381ccb5df764549818d9a7d57e45f1057d30"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.18.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "924cdca592bc16f14d2f7006754a621735280b74"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.1.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.DBFTables]]
deps = ["Printf", "Tables", "WeakRefStrings"]
git-tree-sha1 = "f5b78d021b90307fb7170c4b013f350e6abe8fed"
uuid = "75c7ada1-017a-5fb6-b8c7-2125ff2d6c93"
version = "1.0.0"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataDeps]]
deps = ["BinaryProvider", "HTTP", "Libdl", "Reexport", "SHA", "p7zip_jll"]
git-tree-sha1 = "e299d8267135ef2f9c941a764006697082c1e7e8"
uuid = "124859b0-ceae-595e-8997-d05f6a7a8dfe"
version = "0.7.8"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.GeoDatasets]]
deps = ["CodecZlib", "GeoInterface", "Printf", "RemoteFiles", "Shapefile", "ZipFile"]
git-tree-sha1 = "5ea1a10047cd19f5df9139567c6637a375bd4f8d"
uuid = "ddc7317b-88db-5cb5-a849-8449e5df04f9"
version = "0.1.6"

[[deps.GeoInterface]]
deps = ["RecipesBase"]
git-tree-sha1 = "6b1a29c757f56e0ae01a35918a2c39260e2c4b98"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "0.5.7"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OceanBasins]]
deps = ["DataDeps", "DelimitedFiles", "PolygonOps", "StaticArrays"]
git-tree-sha1 = "35c7c6274418986991573d024e6173126e7fb335"
uuid = "d1bb7020-b2be-4340-9d18-d24ca645bddb"
version = "0.1.7"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "180d744848ba316a3d0fdf4dbd34b77c7242963a"
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.18"

[[deps.PlutoPlotly]]
deps = ["AbstractPlutoDingetjes", "Dates", "HypertextLiteral", "InteractiveUtils", "LaTeXStrings", "Markdown", "PlotlyBase", "PlutoUI", "Reexport"]
git-tree-sha1 = "b470931aa2a8112c8b08e66ea096c6c62c60571e"
uuid = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
version = "0.3.4"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RemoteFiles]]
deps = ["Dates", "FileIO", "HTTP"]
git-tree-sha1 = "54527375d877a64c55190fb762d584f927d6d7c3"
uuid = "cbe49d4c-5af1-5b60-bb70-0a60aa018e1b"
version = "0.4.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Shapefile]]
deps = ["DBFTables", "GeoInterface", "RecipesBase", "Tables"]
git-tree-sha1 = "213498e68fe72d9a62668d58d6be3bc423ebb81f"
uuid = "8e980c4a-a4fe-5da2-b3a7-4b4b0353a2f4"
version = "0.7.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "a9e798cae4867e3a41cae2dd9eb60c047f1212db"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.6"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "2bbd9f2e40afd197a1379aef05e0d85dba649951"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.4.7"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "3593e69e469d2111389a9bd06bac1f3d730ac6de"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.9.4"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─ed82ef42-217d-4ca7-92a4-523fb7203338
# ╠═75816aaa-59be-43fa-b6d5-6be142634cf8
# ╟─1dd172af-436c-4331-8238-f6caabb16c0d
# ╟─5428392e-0d61-4a56-bbdf-64b1572308f8
# ╠═706c90e3-0900-46c1-965a-44435fcd4cea
# ╠═10b3aead-310e-4fb9-9816-6bafec58e097
# ╠═ebb7b2a5-2660-46ce-8a9d-6e935b34371c
# ╠═912b2ae6-27fc-42d8-8650-c1248536aeb1
# ╠═552dd710-db8c-4f13-aceb-994966e1d5a6
# ╠═4958000b-e192-4242-9143-42f7a13d51a1
# ╟─dc4a32d3-3c92-493f-8b3d-ea21eba196ce
# ╠═03768224-ddef-4c0d-8e23-c5ccdba119a9
# ╠═7a6b2d0f-1038-4e57-8b3c-2831787dcc3d
# ╠═479cd750-07e0-462e-8379-64f095c9c9b7
# ╠═0bc57854-b2a2-4cb5-9155-3100c8aae411
# ╠═1d377b9e-e7af-40c7-a32d-8715615ff80c
# ╠═4b08d7ff-e31e-467a-8469-05ab480ac10b
# ╠═2c5477fc-e794-11ec-17ea-7fc681f9a79b
# ╠═7f68b4d5-f2d3-4563-9942-1bbc3ba97f2b
# ╠═cd068126-b9f3-4b0a-8431-fa22344fe6b5
# ╠═7a5968a0-0ba3-44fc-9f4c-d25b5f528d2b
# ╠═44181dab-060b-4b5b-85f8-cf0245bdfa89
# ╠═d85676a2-ea69-4532-921a-b61c922a99f5
# ╠═9f256c6c-6d82-48b0-b91f-ddd664f279a5
# ╠═26789f57-0cba-4f3e-9f95-9a005ee032ab
# ╠═c477bd21-94b8-435d-8aa0-7bd4c75cf231
# ╠═44762d59-d3ea-4144-b4c5-3b9db3bf08a6
# ╠═a952f635-5eea-4b67-9ff9-46a7a25de9dc
# ╠═35897111-72c9-4479-a481-87cf2cc0cdea
# ╠═f417361a-70ae-4070-ae08-9e3491388d68
# ╟─f562a079-ee48-434a-8c93-7f7fe149a553
# ╠═1c346ac8-2842-4454-a22c-da4842ce29fa
# ╟─00587f0c-ef2c-4133-b2c8-a7019076d99d
# ╠═aa87d1a0-5378-4fd9-9476-f9af246aa549
# ╠═65e3b758-0f59-4447-82d4-0c28126199c9
# ╠═5525e152-f81a-4eae-81bf-224303583883
# ╠═f44739a6-a46f-48af-b4e8-978f45895b35
# ╠═3e96a1f7-1e42-488b-bf50-89c76dd9a918
# ╠═90cc011b-cf18-4121-84d1-46ffcb5fdcc1
# ╠═f1ff33a1-b4de-4a07-9a94-28c874d2ab07
# ╠═343df1af-99ef-47fa-a5c7-46278d27cf7f
# ╠═f4d2e8c2-7717-4181-aaf7-602bd1b7a5de
# ╠═f776dabd-fb61-494f-a33d-14379458ea2e
# ╠═3f17298c-49b3-4937-a3d0-ea2c1b1fb4da
# ╠═9aa47be6-08b7-43bc-8a5f-20acc081c121
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002